//
//  PetCatalog.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-12.
//

import Foundation

public struct PetCatalog: Codable, Equatable {
    public let version: String
    public let pets: [PetCatalogItem]
}

public struct PetCatalogItem: Codable, Equatable {
    public let type: String
    public let name: String
    public let displayOrder: Int
    public let isActive: Bool
    // 키 "1"~"5" 등 레벨 문자열. Int 키 변환은 후속 Repository에서 수행.
    public let levels: [String: PetCatalogLevel]
    public let backgrounds: PetCatalogBackgrounds
}

public struct PetCatalogLevel: Codable, Equatable {
    public let imageUrl: String
    public let lottieDefaultUrl: String
    public let lottiePlayEatUrl: String
}

public struct PetCatalogBackgrounds: Codable, Equatable {
    public let homeUrl: String
    public let homeCompactUrl: String
    public let friendCardUrl: String
}
