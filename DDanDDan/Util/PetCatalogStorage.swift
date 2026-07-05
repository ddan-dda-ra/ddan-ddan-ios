//
//  PetCatalogStorage.swift
//  DDanDDan
//
//  Created by Codex on 2026-07-01.
//

import Foundation

public protocol PetCatalogStoring: Sendable {
    func load() async -> PetCatalogResponse?
    func save(_ catalog: PetCatalogResponse) async throws
}

public actor PetCatalogStorage: PetCatalogStoring {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let revisionStore: any PetCatalogRevisionStoring

    public init(
        appGroup: String = "group.com.DdanDdan",
        fileURL: URL? = nil,
        revisionStore: any PetCatalogRevisionStoring = PetCatalogRevisionStore.shared
    ) {
        self.revisionStore = revisionStore
        if let fileURL {
            self.fileURL = fileURL
            return
        }
        let fm = FileManager.default
        let root: URL
        if let container = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            root = container.appendingPathComponent("PetCatalog", isDirectory: true)
        } else {
            let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            root = support.appendingPathComponent("DDanDDan/PetCatalog", isDirectory: true)
        }
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)
        self.fileURL = root.appendingPathComponent("catalog.json")
    }

    public func load() -> PetCatalogResponse? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        guard let catalog = try? decoder.decode(PetCatalogResponse.self, from: data) else { return nil }
        revisionStore.saveRevision(catalog.revision)
        return catalog
    }

    public func save(_ catalog: PetCatalogResponse) throws {
        let data = try encoder.encode(catalog)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        revisionStore.saveRevision(catalog.revision)
    }
}
