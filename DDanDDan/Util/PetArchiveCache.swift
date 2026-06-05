//
//  PetArchiveCache.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-06-02.
//

import Foundation

/// 펫 보관함 응답(`PetArchiveModel`)을 프로세스 메모리에 보관하여
/// 마이페이지 → 펫 보관함 진입 체감 로딩을 줄인다.
/// stale-while-revalidate 정책: 호출자는 캐시된 값을 즉시 받아 그리고,
/// 백그라운드에서 최신 값으로 한 번 더 갱신한다.
public actor PetArchiveCache {
    public static let shared = PetArchiveCache()

    /// 캐시 적재 시각 — TTL 비교에 사용.
    private struct Entry {
        let value: PetArchiveModel
        let fetchedAt: Date
    }

    private var entry: Entry?
    /// 진행 중인 fetch Task. 동시 진입 시 join 대상.
    private var inflight: Task<Result<PetArchiveModel, NetworkError>, Never>?

    /// prefetch가 새 fetch를 발화시키지 않는 신선도 기준(초).
    private let prefetchTTL: TimeInterval = 60

    public init() {}

    /// 캐시 스냅샷. nil이면 캐시 미스.
    public func cachedValue() -> PetArchiveModel? {
        entry?.value
    }

    /// 항상 fetch를 보장한다(or join). on-tap refresh / stale-while-revalidate에 사용.
    /// 반환값은 최신 Result. 호출자가 캐시 값을 미리 그렸다면 도착 후 한 번 더 그리면 된다.
    public func fetch(
        using fetcher: @Sendable @escaping () async -> Result<PetArchiveModel, NetworkError>
    ) async -> Result<PetArchiveModel, NetworkError> {
        if let task = inflight {
            return await task.value
        }
        let task = Task<Result<PetArchiveModel, NetworkError>, Never> {
            await fetcher()
        }
        inflight = task
        let result = await task.value
        inflight = nil
        if case .success(let value) = result {
            entry = Entry(value: value, fetchedAt: Date())
        }
        return result
    }

    /// prefetch 트리거. 다음 조건 중 하나면 skip:
    /// - 이미 진행 중인 fetch가 있다.
    /// - 캐시가 신선하다(`fetchedAt`이 TTL 이내).
    /// 그 외에는 `fetch(using:)`을 발화하되 반환값은 버린다.
    public func prefetchIfNeeded(
        using fetcher: @Sendable @escaping () async -> Result<PetArchiveModel, NetworkError>
    ) async {
        if inflight != nil { return }
        if let entry, Date().timeIntervalSince(entry.fetchedAt) < prefetchTTL { return }
        _ = await fetch(using: fetcher)
    }

    /// 메인 펫 변경 등 캐시 무효화 사유 발생 시 호출.
    /// 진행 중 fetch도 cancel하여 stale 응답이 캐시를 재오염시키지 않도록 한다.
    public func invalidate() {
        inflight?.cancel()
        inflight = nil
        entry = nil
    }
}
