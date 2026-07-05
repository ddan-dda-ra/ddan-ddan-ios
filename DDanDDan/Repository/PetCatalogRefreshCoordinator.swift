import Foundation

public protocol PetCatalogRefreshCoordinating: Sendable {
    func requestRefresh() async
}

public actor PetCatalogRefreshCoordinator: PetCatalogRefreshCoordinating {
    public static let shared = PetCatalogRefreshCoordinator {
        _ = await PetCatalogRepository.shared.sync()
    }

    private let refresh: @Sendable () async -> Void
    private var inflight: Task<Void, Never>?
    private var inflightID: UUID?

    public init(refresh: @escaping @Sendable () async -> Void) {
        self.refresh = refresh
    }

    public func requestRefresh() {
        guard inflight == nil else { return }
        let id = UUID()
        let refresh = self.refresh
        let task = Task { await refresh() }
        inflight = task
        inflightID = id
        Task { [weak self] in
            await task.value
            await self?.finish(id: id)
        }
    }

    private func finish(id: UUID) {
        guard inflightID == id else { return }
        inflight = nil
        inflightID = nil
    }
}
