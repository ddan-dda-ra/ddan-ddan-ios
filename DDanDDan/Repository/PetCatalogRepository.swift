//
//  PetCatalogRepository.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-13.
//

import Foundation
import UIKit
import Dependencies

/// 펫 카탈로그 단일 진실원(actor).
/// - 메모리 + App Group UserDefaults 영속화
/// - 6h TTL 게이트 + `currentSyncTask` dedup
/// - 헤더 `X-Pet-Catalog-Version` 우선, 폴백 body version
/// - 버전 변경 시 이미지 URL prefetch (백그라운드)
public actor PetCatalogRepository {
    // MARK: - State
    private var cachedCatalog: PetCatalog?
    private var lastSyncedAt: Date?
    private var lastSeenVersion: String?
    private var currentSyncTask: Task<PetCatalog, Error>?

    // MARK: - Collaborators
    private let network: PetCatalogNetwork
    private let cache: PetAssetCache
    private let appGroupID: String

    // MARK: - Constants
    /// App Group UserDefaults 키 — 버전 문자열.
    private static let versionKey = "petCatalogVersion"
    /// App Group UserDefaults 키 — 카탈로그 JSON 원본.
    private static let catalogKey = "petCatalogJSON"
    /// App Group UserDefaults 키 — 마지막 동기화 시각(timeIntervalSinceReferenceDate, Double).
    /// 앱 재시작 후에도 6시간 TTL 게이트가 유지되도록 영속화한다.
    private static let lastSyncedAtKey = "petCatalogLastSyncedAt"
    /// 6시간 TTL (force=false 경로에서만 적용).
    private static let ttl: TimeInterval = 6 * 60 * 60

    // MARK: - Init
    public init(
        network: PetCatalogNetwork,
        cache: PetAssetCache,
        appGroupID: String
    ) {
        self.network = network
        self.cache = cache
        self.appGroupID = appGroupID
        // 영속화된 TTL 메타데이터 복원. 앱 재시작 직후 첫 sync 호출이 TTL 게이트를 적절히 통과/노옵하게 한다.
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        let storedTimestamp = defaults.double(forKey: Self.lastSyncedAtKey)
        if storedTimestamp > 0 {
            self.lastSyncedAt = Date(timeIntervalSinceReferenceDate: storedTimestamp)
        }
        if let version = defaults.string(forKey: Self.versionKey) {
            self.lastSeenVersion = version
        }
    }

    // MARK: - Public API

    /// 현재 보유한 카탈로그를 반환한다. 메모리 캐시를 반환하기 전에 App Group 의 저장된
    /// 메타데이터(version/lastSyncedAt)와 비교하여, 다른 프로세스(메인 앱·Widget·Watch)가
    /// 더 최신 카탈로그를 써둔 경우 stale 캐시를 갱신한다. 네트워크 호출은 하지 않는다.
    public func currentCatalog() -> PetCatalog? {
        let defaults = appGroupDefaults()
        let storedVersion = defaults.string(forKey: Self.versionKey)
        let storedTimestamp = defaults.double(forKey: Self.lastSyncedAtKey)

        let shouldReload: Bool = {
            // 메모리 캐시 자체가 없으면 무조건 디스크에서 복원 시도.
            guard cachedCatalog != nil else { return true }
            // 디스크 버전 또는 sync 시각이 메모리보다 새것이면 갱신.
            if let storedVersion, storedVersion != lastSeenVersion { return true }
            if storedTimestamp > 0,
               let memTimestamp = lastSyncedAt?.timeIntervalSinceReferenceDate,
               storedTimestamp > memTimestamp { return true }
            return false
        }()

        if shouldReload, let restored = restoreFromAppGroupUserDefaults() {
            cachedCatalog = restored
            if storedTimestamp > 0 {
                lastSyncedAt = Date(timeIntervalSinceReferenceDate: storedTimestamp)
            }
        }
        return cachedCatalog
    }

    /// 카탈로그 sync. TTL/dedup 게이트 통과 시 네트워크 호출.
    /// - Parameter force: `true` 면 TTL 무시. 로그인 직후 등 강제 갱신용.
    /// - Returns: 최신(또는 캐시된) `PetCatalog`.
    /// - Throws: 네트워크 실패 시 `NetworkError` 전파.
    @discardableResult
    public func syncIfNeeded(force: Bool = false) async throws -> PetCatalog {
        // 1) 진행 중 sync 가 있으면 결과 공유 (dedup)
        if let task = currentSyncTask {
            return try await task.value
        }

        // 2) TTL 게이트 — force=false 이고 6h 이내라면 캐시 반환
        if !force,
           let last = lastSyncedAt,
           Date().timeIntervalSince(last) < Self.ttl,
           let cached = currentCatalog() {
            return cached
        }

        // 3) 신규 sync Task 등록 (self 직접 캡처: actor 격리됨)
        let task = Task<PetCatalog, Error> {
            let result = await network.fetchCatalog()
            switch result {
            case .failure(let error):
                throw error
            case .success(let payload):
                let newVersion = payload.version ?? payload.catalog.version
                let versionChanged = (newVersion != self.lastSeenVersion)
                self.cachedCatalog = payload.catalog
                self.lastSeenVersion = newVersion
                self.lastSyncedAt = Date()
                self.persistToAppGroupUserDefaults(
                    catalog: payload.catalog,
                    version: newVersion
                )
                if versionChanged {
                    // prefetch 는 sync 반환 차단을 막기 위해 분리 Task 로 백그라운드 실행.
                    let urls = self.collectImageURLs(from: payload.catalog)
                    let cache = self.cache
                    Task {
                        await cache.prefetch(urls: urls)
                    }
                }
                return payload.catalog
            }
        }
        currentSyncTask = task
        defer { currentSyncTask = nil }
        return try await task.value
    }

    /// 타입/레벨에 대응하는 펫 이미지. 카탈로그 → cache.image → 번들 폴백.
    /// 카탈로그가 비어 있어도 sync가 진행 중이면 결과를 대기한 뒤 한 번 더 시도하여,
    /// 콜드 스타트 시점에 첫 조회가 번들 이미지로 고착되는 것을 막는다.
    public func image(for type: PetType, level: Int) async -> UIImage {
        let safeLevel = max(1, min(level, 5))

        // 카탈로그 확보: 메모리/디스크 → 진행 중 sync 결과 대기.
        var catalog: PetCatalog? = currentCatalog()
        if catalog == nil, let syncTask = currentSyncTask {
            catalog = try? await syncTask.value
        }

        // 1) 카탈로그 URL 조회 → 캐시 hit
        if let catalog,
           let item = catalog.pets.first(where: { $0.type == type.rawValue }),
           let levelEntry = item.levels[String(safeLevel)],
           let url = URL(string: levelEntry.imageUrl),
           let image = await cache.image(for: url) {
            return image
        }

        // 2) 번들 폴백 — 기존 PetType.image(for:)
        let resource = type.image(for: safeLevel)
        return UIImage(resource: resource)
    }

    // MARK: - Persistence Helpers

    /// 카탈로그를 App Group UserDefaults 에 JSON 직렬화하여 저장.
    /// 컨테이너 접근 실패 시 standard UserDefaults 폴백.
    /// `lastSyncedAt` 도 함께 영속화하여 앱 재시작 후 TTL 게이트가 살아있도록 한다.
    private func persistToAppGroupUserDefaults(catalog: PetCatalog, version: String) {
        let defaults = appGroupDefaults()
        do {
            let data = try JSONEncoder().encode(catalog)
            defaults.set(data, forKey: Self.catalogKey)
            defaults.set(version, forKey: Self.versionKey)
            if let lastSyncedAt {
                defaults.set(lastSyncedAt.timeIntervalSinceReferenceDate, forKey: Self.lastSyncedAtKey)
            }
        } catch {
            print("⚠️ PetCatalogRepository: persist 실패 - \(error.localizedDescription)")
        }
    }

    /// App Group UserDefaults 에서 카탈로그 복원. 디코드 실패 시 nil.
    private func restoreFromAppGroupUserDefaults() -> PetCatalog? {
        let defaults = appGroupDefaults()
        guard let data = defaults.data(forKey: Self.catalogKey) else {
            return nil
        }
        do {
            let catalog = try JSONDecoder().decode(PetCatalog.self, from: data)
            if let version = defaults.string(forKey: Self.versionKey) {
                lastSeenVersion = version
            }
            return catalog
        } catch {
            print("⚠️ PetCatalogRepository: restore 디코드 실패 - \(error.localizedDescription)")
            return nil
        }
    }

    /// 카탈로그 각 레벨의 imageUrl 을 URL 로 변환해 모아 반환. prefetch 대상.
    private func collectImageURLs(from catalog: PetCatalog) -> [URL] {
        var urls: [URL] = []
        for pet in catalog.pets {
            for (_, level) in pet.levels {
                if let url = URL(string: level.imageUrl) {
                    urls.append(url)
                }
            }
        }
        return urls
    }

    /// App Group UserDefaults 접근. 실패 시 standard 폴백 + 로그.
    private func appGroupDefaults() -> UserDefaults {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            return defaults
        }
        print("⚠️ PetCatalogRepository: App Group '\(appGroupID)' UserDefaults missing — fallback to standard")
        return .standard
    }
}

// MARK: - DependencyKey

extension PetCatalogRepository: DependencyKey {
    /// App, Widget, Watch 가 같은 actor 인스턴스를 공유하도록 단일 instance 유지.
    public static let liveValue: PetCatalogRepository = PetCatalogRepository(
        network: PetCatalogNetwork(),
        cache: PetAssetCache.shared,
        appGroupID: "group.com.DdanDdan"
    )
}
