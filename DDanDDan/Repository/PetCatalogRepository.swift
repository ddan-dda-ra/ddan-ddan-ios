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

    /// sign-up 진입 시 로컬 카탈로그만 publish한다.
    /// 선택 펫이 확정되기 전 전체 에셋을 다운로드하지 않고, 가입 완료의 prepareForMain이 필수 에셋만 준비한다.
    func startAuthenticatedRefresh() async {
        _ = await loadLocal()
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
    private var inflightDownloadsAllAssets = false
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
        let prepared: PetCatalogSnapshot
        let usedLocalCatalog: Bool
        if requiredAssetURLs(petType: petType, level: level, snapshot: local) != nil {
            prepared = local
            usedLocalCatalog = true
        } else {
            let synced = await sync(requiredMainPet: (petType, level))
            guard case let .success(snapshot) = synced else { return synced }
            prepared = snapshot
            usedLocalCatalog = false
        }

        guard let requiredURLs = requiredAssetURLs(petType: petType, level: level, snapshot: prepared) else {
            return .failure(.requestFailed("메인 펫 카탈로그를 찾을 수 없습니다."))
        }
        let result = await download(requiredURLs)
        guard result.isComplete else {
            return .failure(.requestFailed("필수 펫 에셋을 준비하지 못했습니다."))
        }
        if usedLocalCatalog {
            Task { _ = await sync() }
        }
        return .success(prepared)
    }

    @discardableResult
    public func sync() async -> Result<PetCatalogSnapshot, NetworkError> {
        await sync(requiredMainPet: nil)
    }

    private func sync(
        requiredMainPet: (type: String, level: Int)?
    ) async -> Result<PetCatalogSnapshot, NetworkError> {
        if let inflight {
            let joinedID = inflightID
            let joinedDownloadsAllAssets = inflightDownloadsAllAssets
            let result = await inflight.value
            guard requiredMainPet == nil, !joinedDownloadsAllAssets else { return result }
            if inflightID == joinedID {
                self.inflight = nil
                inflightID = nil
                inflightDownloadsAllAssets = false
            }
            return await sync(requiredMainPet: nil)
        }

        let taskID = UUID()
        let expectedGeneration = generation
        let oldSnapshot = snapshot
        let task = Task<Result<PetCatalogSnapshot, NetworkError>, Never> { [weak self] in
            guard let self else { return .failure(.requestFailed("PetCatalogRepository released")) }
            return await self.performSync(
                expectedGeneration: expectedGeneration,
                oldSnapshot: oldSnapshot,
                requiredMainPet: requiredMainPet
            )
        }
        inflight = task
        inflightID = taskID
        inflightDownloadsAllAssets = requiredMainPet == nil
        let result = await task.value
        if inflightID == taskID {
            inflight = nil
            inflightID = nil
            inflightDownloadsAllAssets = false
        }
        return result
    }

    private func performSync(
        expectedGeneration: UInt64,
        oldSnapshot: PetCatalogSnapshot,
        requiredMainPet: (type: String, level: Int)?
    ) async -> Result<PetCatalogSnapshot, NetworkError> {
        let response = await network.fetchCatalog()
        guard case let .success(catalog) = response else {
            if case let .failure(error) = response { return .failure(error) }
            return .failure(.invalidResponse)
        }

        if catalog.revision == oldSnapshot.revision {
            let targetURLs: Set<URL>
            if let requiredMainPet {
                guard let required = requiredAssetURLs(
                    petType: requiredMainPet.type,
                    level: requiredMainPet.level,
                    snapshot: oldSnapshot
                ) else { return .failure(.invalidResponse) }
                targetURLs = required
            } else {
                targetURLs = oldSnapshot.assetURLs
            }
            let missingURLs = await targetURLs.asyncFilter { !(await cache.contains($0)) }
            guard (await download(missingURLs)).isComplete else {
                return .failure(.requestFailed("펫 카탈로그 에셋 다운로드에 실패했습니다."))
            }
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
        let targetURLs: Set<URL>
        if let requiredMainPet {
            guard let required = requiredAssetURLs(
                petType: requiredMainPet.type,
                level: requiredMainPet.level,
                snapshot: candidate
            ) else { return .failure(.invalidResponse) }
            targetURLs = required
        } else {
            targetURLs = candidate.assetURLs
        }
        let expectedAssetCount = targetURLs.count
        let urlsToDownload = await targetURLs.asyncFilter {
            let isNewURL = !oldSnapshot.assetURLs.contains($0)
            if isNewURL { return true }
            let isCached = await cache.contains($0)
            return !isCached
        }
        let batch = await download(urlsToDownload)
        let alreadyCachedCount = targetURLs.count - urlsToDownload.count
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

    private func requiredAssetURLs(
        petType: String,
        level: Int,
        snapshot: PetCatalogSnapshot
    ) -> Set<URL>? {
        let presentation = PetPresentation.resolve(petType: petType, petLevel: level, snapshot: snapshot)
        guard let selectedLevel = presentation.level,
              selectedLevel.assetURLs.count == 3 else { return nil }
        return selectedLevel.assetURLs
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
