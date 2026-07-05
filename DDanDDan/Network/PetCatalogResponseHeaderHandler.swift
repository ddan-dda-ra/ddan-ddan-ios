import Foundation

public protocol PetCatalogResponseHeaderHandling: Sendable {
    func handle(response: HTTPURLResponse, requestURL: URL) async
}

public struct PetCatalogResponseHeaderHandler: PetCatalogResponseHeaderHandling, Sendable {
    public static let downloadRequiredHeader = "X-Pet-Catalog-Download-Required"
    private let coordinator: any PetCatalogRefreshCoordinating

    public init(coordinator: any PetCatalogRefreshCoordinating = PetCatalogRefreshCoordinator.shared) {
        self.coordinator = coordinator
    }

    public func handle(response: HTTPURLResponse, requestURL: URL) async {
        let path = requestURL.path
        guard path.hasPrefix("/v1/"),
              path != "/v1/auth/login",
              path != "/v1/pets/catalog",
              headerValue(in: response)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        else { return }
        await coordinator.requestRefresh()
    }

    private func headerValue(in response: HTTPURLResponse) -> String? {
        if let value = response.value(forHTTPHeaderField: Self.downloadRequiredHeader) { return value }
        for (key, value) in response.allHeaderFields {
            if String(describing: key).caseInsensitiveCompare(Self.downloadRequiredHeader) == .orderedSame {
                return String(describing: value)
            }
        }
        return nil
    }
}
