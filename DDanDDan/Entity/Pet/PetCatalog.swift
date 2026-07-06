//
//  PetCatalog.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-12.
//

import Foundation

public struct PetCatalogResponse: Codable, Equatable, Sendable {
    public let revision: String
    public let pets: [PetCatalogItem]
}

public struct PetCatalogItem: Codable, Equatable, Sendable {
    public let type: String
    public let name: String
    public let colorCode: String
    public let displayOrder: Int
    public let levels: [PetCatalogLevel]

    public func selectedLevel(for petLevel: Int) -> PetCatalogLevel? {
        levels
            .filter { (1...5).contains($0.level) && $0.level <= petLevel }
            .max { $0.level < $1.level }
    }
}

public struct PetCatalogLevel: Codable, Equatable, Sendable {
    public let level: Int
    public let imageUrl: String
    public let lottieDefaultUrl: String
    public let lottiePlayEatUrl: String

    public var assetURLs: Set<URL> {
        Set([imageURL, defaultLottieURL, playEatLottieURL].compactMap { $0 })
    }

    public var imageURL: URL? { Self.absoluteHTTPURL(imageUrl, expectedExtension: "svg") }
    public var defaultLottieURL: URL? { Self.absoluteHTTPURL(lottieDefaultUrl, expectedExtension: "json") }
    public var playEatLottieURL: URL? { Self.absoluteHTTPURL(lottiePlayEatUrl, expectedExtension: "json") }

    private static func absoluteHTTPURL(_ value: String, expectedExtension: String? = nil) -> URL? {
        guard let url = URL(string: value),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host?.isEmpty == false,
              expectedExtension == nil || url.pathExtension.lowercased() == expectedExtension else { return nil }
        return url
    }
}

public struct PetCatalogSnapshot: Equatable, Sendable {
    public static let empty = PetCatalogSnapshot(revision: "", pets: [])

    public let revision: String
    public let pets: [PetCatalogItem]
    public let catalogByType: [String: PetCatalogItem]

    public init(revision: String, pets: [PetCatalogItem]) {
        self.revision = revision
        self.pets = pets.sorted { $0.displayOrder < $1.displayOrder }
        self.catalogByType = pets.reduce(into: [:]) { result, item in
            let key = Self.canonicalType(item.type)
            guard !key.isEmpty else { return }
            result[key] = item
        }
    }

    public static func canonicalType(_ type: String) -> String {
        type.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    public var assetURLs: Set<URL> {
        Set(pets.flatMap { $0.levels.flatMap(\.assetURLs) })
    }
}

public struct PetPresentation: Equatable, Sendable {
    public let type: String
    public let name: String
    public let colorCode: String?
    public let level: PetCatalogLevel?

    public var usesPlaceholder: Bool { level == nil }

    public static func resolve(petType: String, petLevel: Int, snapshot: PetCatalogSnapshot) -> Self {
        let canonicalType = PetCatalogSnapshot.canonicalType(petType)
        guard let item = snapshot.catalogByType[canonicalType] else {
            return .init(type: petType, name: "알 수 없는 펫", colorCode: nil, level: nil)
        }
        return .init(
            type: canonicalType,
            name: item.name,
            colorCode: Self.validHex(item.colorCode),
            level: item.selectedLevel(for: petLevel).flatMap {
                ($0.imageURL != nil || $0.defaultLottieURL != nil || $0.playEatLottieURL != nil) ? $0 : nil
            }
        )
    }

    private static func validHex(_ value: String) -> String? {
        let pattern = "^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$"
        return value.range(of: pattern, options: .regularExpression) == nil ? nil : value
    }
}
