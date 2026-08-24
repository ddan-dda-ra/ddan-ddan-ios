import Foundation

public protocol PetCatalogRevisionProviding: Sendable {
    var currentRevision: String { get }
}

public protocol PetCatalogRevisionStoring: PetCatalogRevisionProviding {
    func saveRevision(_ revision: String)
}

public final class PetCatalogRevisionStore: PetCatalogRevisionStoring, @unchecked Sendable {
    public static let shared = PetCatalogRevisionStore()
    public static let epochRevision = "1970-01-01T00:00:00Z"

    private let defaults: UserDefaults
    private let key: String
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard, key: String = "petCatalogRevision") {
        self.defaults = defaults
        self.key = key
    }

    public var currentRevision: String {
        lock.withLock { defaults.string(forKey: key) ?? Self.epochRevision }
    }

    public func saveRevision(_ revision: String) {
        lock.withLock { defaults.set(revision, forKey: key) }
    }
}
