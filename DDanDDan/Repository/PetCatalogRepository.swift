//
//  PetCatalogRepository.swift
//  DDanDDan
//
//  Created by Codex on 2026-07-01.
//

import Foundation
import Dependencies

@MainActor
public final class PetCatalogStore: ObservableObject {
    public static let shared = PetCatalogStore()
    @Published public private(set) var snapshot: PetCatalogSnapshot = .empty

    public func publish(_ snapshot: PetCatalogSnapshot) {
        guard self.snapshot != snapshot else { return }
        self.snapshot = snapshot
    }
}

public struct PetAssetBatchResult: Equatable, Sendable {
    public let cacheHits: Set<URL>
    public let downloaded: Set<URL>
    public let failures: Set<URL>

    public var isComplete: Bool { failures.isEmpty }
}

public protocol PetCatalogRepositoryProtocol: Sendable {
    @discardableResult func loadLocal() async -> PetCatalogSnapshot
    @discardableResult func sync() async -> Result<PetCatalogSnapshot, NetworkError>
    @discardableResult func prepareForMain(petType: String, level: Int) async -> Result<PetCatalogSnapshot, NetworkError>
    @discardableResult func bootstrapAfterAuthentication() async -> Result<PetCatalogSnapshot, NetworkError>
}

public extension PetCatalogRepositoryProtocol {
    func prepareForMain(petType: String, level: Int) async -> Result<PetCatalogSnapshot, NetworkError> {
        await bootstrapAfterAuthentication()
    }

    /// 인증 완료 후 카탈로그를 준비한다. 로컬이 있으면 즉시 반환하고 서버 갱신은 background에서 수행한다.
    /// 로컬이 비어 있으면 첫 화면 진입 전에 server snapshot publish까지 기다린다.
    func bootstrapAfterAuthentication() async -> Result<PetCatalogSnapshot, NetworkError> {
        let local = await loadLocal()
        if !local.pets.isEmpty {
            return .success(local)
        }
        return await sync()
    }

    /// sign-up처럼 메인 UI를 아직 표시하지 않는 인증 경로에서 blocking 없이 갱신을 시작한다.
    func startAuthenticatedRefresh() async {
        _ = await loadLocal()
        Task { _ = await sync() }
    }
}

public actor PetCatalogRepository: PetCatalogRepositoryProtocol {
    public static let shared = PetCatalogRepository()

    private let network: any PetCatalogNetworking
    private let storage: any PetCatalogStoring
    private let cache: any PetAssetCaching
    private var snapshot: PetCatalogSnapshot = .empty
    private var inflight: Task<Result<PetCatalogSnapshot, NetworkError>, Never>?
    private var inflightID: UUID?
    private var generation: UInt64 = 0

    public init(
        network: any PetCatalogNetworking = PetCatalogNetwork(),
        storage: any PetCatalogStoring = PetCatalogStorage(),
        cache: any PetAssetCaching = PetAssetCache.shared
    ) {
        self.network = network
        self.storage = storage
        self.cache = cache
    }

    @discardableResult
    public func loadLocal() async -> PetCatalogSnapshot {
        guard let catalog = await storage.load() else {
            return snapshot
        }
        let local = PetCatalogSnapshot(revision: catalog.revision, pets: catalog.pets)
        guard snapshot != local else { return snapshot }
        snapshot = local
        generation &+= 1
        await publish(snapshot)
        return snapshot
    }

    @discardableResult
    public func bootstrapAfterAuthentication() async -> Result<PetCatalogSnapshot, NetworkError> {
        await prepareForMain(petType: UserDefaultValue.petType, level: UserDefaultValue.level)
    }

    @discardableResult
    public func prepareForMain(petType: String, level: Int) async -> Result<PetCatalogSnapshot, NetworkError> {
        let local = await loadLocal()
        if !local.pets.isEmpty {
            let presentation = PetPresentation.resolve(petType: petType, petLevel: level, snapshot: local)
            guard let selectedLevel = presentation.level else {
                return await sync()
            }
            let requiredURLs = selectedLevel.assetURLs
            guard requiredURLs.count == 3 else {
                return .failure(.requestFailed("메인 펫 에셋 URL이 유효하지 않습니다."))
            }
            let result = await download(requiredURLs)
            guard result.isComplete else {
                return .failure(.requestFailed("필수 펫 에셋을 준비하지 못했습니다."))
            }
            Task { _ = await sync() }
            return .success(local)
        }
        return await sync()
    }

    @discardableResult
    public func sync() async -> Result<PetCatalogSnapshot, NetworkError> {
        if let inflight { return await inflight.value }

        let taskID = UUID()
        let expectedGeneration = generation
        let oldSnapshot = snapshot
        let task = Task<Result<PetCatalogSnapshot, NetworkError>, Never> { [weak self] in
            guard let self else { return .failure(.requestFailed("PetCatalogRepository released")) }
            return await self.performSync(expectedGeneration: expectedGeneration, oldSnapshot: oldSnapshot)
        }
        inflight = task
        inflightID = taskID
        let result = await task.value
        if inflightID == taskID {
            inflight = nil
            inflightID = nil
        }
        return result
    }

    private func performSync(
        expectedGeneration: UInt64,
        oldSnapshot: PetCatalogSnapshot
    ) async -> Result<PetCatalogSnapshot, NetworkError> {
        let response = await network.fetchCatalog()
        guard case let .success(catalog) = response else {
            if case let .failure(error) = response { return .failure(error) }
            return .failure(.invalidResponse)
        }

        if catalog.revision == oldSnapshot.revision {
            let missingURLs = await oldSnapshot.assetURLs.asyncFilter { !(await cache.contains($0)) }
            _ = await download(missingURLs)
            return .success(snapshot)
        }

        let candidate = PetCatalogSnapshot(revision: catalog.revision, pets: catalog.pets)
        guard !candidate.pets.isEmpty else {
            return .failure(.invalidResponse)
        }
        let allLevels = catalog.pets.flatMap(\.levels)
        guard !allLevels.isEmpty,
              allLevels.allSatisfy({ $0.assetURLs.count == 3 }) else {
            return .failure(.invalidResponse)
        }
        let expectedAssetCount = candidate.assetURLs.count
        let urlsToDownload = await candidate.assetURLs.asyncFilter {
            let isNewURL = !oldSnapshot.assetURLs.contains($0)
            if isNewURL { return true }
            let isCached = await cache.contains($0)
            return !isCached
        }
        let batch = await download(urlsToDownload)
        let alreadyCachedCount = candidate.assetURLs.count - urlsToDownload.count
        guard batch.isComplete,
              alreadyCachedCount + batch.cacheHits.count + batch.downloaded.count == expectedAssetCount else {
            return .failure(.requestFailed("펫 카탈로그 에셋 다운로드에 실패했습니다."))
        }

        guard expectedGeneration == generation else { return .success(snapshot) }
        do {
            try await storage.save(catalog)
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
        snapshot = candidate
        generation &+= 1
        await publish(candidate)
        return .success(candidate)
    }

    private func download(_ urls: Set<URL>) async -> PetAssetBatchResult {
        let cache = self.cache
        var hits = Set<URL>()
        var downloaded = Set<URL>()
        var failures = Set<URL>()
        let pending = Array(urls)
        for start in stride(from: 0, to: pending.count, by: 8) {
            let end = min(start + 8, pending.count)
            let results = await withTaskGroup(of: (URL, Bool, Bool).self, returning: [(URL, Bool, Bool)].self) { group in
                for url in pending[start..<end] {
                    group.addTask {
                        if await cache.contains(url) { return (url, true, true) }
                        return (url, false, await cache.download(url) != nil)
                    }
                }
                var values: [(URL, Bool, Bool)] = []
                for await value in group { values.append(value) }
                return values
            }
            for (url, wasHit, success) in results {
                if wasHit { hits.insert(url) }
                else if success { downloaded.insert(url) }
                else { failures.insert(url) }
            }
        }
        return .init(cacheHits: hits, downloaded: downloaded, failures: failures)
    }

    private func publish(_ snapshot: PetCatalogSnapshot) async {
        await PetCatalogStore.shared.publish(snapshot)
    }
}

extension PetCatalogRepository: DependencyKey {
    public static let liveValue = PetCatalogRepository.shared
}

private extension Sequence where Element == URL {
    func asyncFilter(_ predicate: (URL) async -> Bool) async -> Set<URL> {
        var result = Set<URL>()
        for element in self where await predicate(element) { result.insert(element) }
        return result
    }
}
