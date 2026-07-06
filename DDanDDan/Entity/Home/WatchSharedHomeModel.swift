//
//  WatchSharedHomeModel.swift
//  DDanDDan
//
//  Created by 이지희 on 11/30/24.
//

import SwiftUI

enum WatchPetSyncKey {
    static let purposeKcal = "purposeKcal"
    static let petType = "petType"
    static let level = "level"
    static let colorCode = "petColorCode"
    static let assetIdentity = "petAssetIdentity"
}

struct WatchPetSyncMetadata: Equatable {
    let purposeKcal: Int
    let petType: String
    let level: Int
    let colorCode: String
    let assetIdentity: String

    var dictionary: [String: Any] {
        [
            WatchPetSyncKey.purposeKcal: purposeKcal,
            WatchPetSyncKey.petType: petType,
            WatchPetSyncKey.level: level,
            WatchPetSyncKey.colorCode: colorCode,
            WatchPetSyncKey.assetIdentity: assetIdentity
        ]
    }

    init(purposeKcal: Int, petType: String, level: Int, colorCode: String, assetIdentity: String) {
        self.purposeKcal = purposeKcal
        self.petType = petType
        self.level = level
        self.colorCode = colorCode
        self.assetIdentity = assetIdentity
    }

    init?(dictionary: [String: Any]) {
        guard let purposeKcal = dictionary[WatchPetSyncKey.purposeKcal] as? NSNumber,
              let petType = dictionary[WatchPetSyncKey.petType] as? String,
              let level = dictionary[WatchPetSyncKey.level] as? NSNumber,
              let colorCode = dictionary[WatchPetSyncKey.colorCode] as? String,
              let assetIdentity = dictionary[WatchPetSyncKey.assetIdentity] as? String else { return nil }
        self.init(
            purposeKcal: purposeKcal.intValue,
            petType: petType,
            level: level.intValue,
            colorCode: colorCode,
            assetIdentity: assetIdentity
        )
    }
}

struct WatchPetModel: Codable {
    var petType: PetType
    var goalKcal: Int
    var level: Int
}

public enum PetType: String, Codable {
    case pinkCat = "CAT"
    case greenHam = "HAMSTER"
    case purpleDog = "DOG"
    case bluePenguin = "PENGUIN"
    case grayMole = "MOLE"
    
    var color: Color {
        switch self {
        case .pinkCat: return Color(hex: "#FD85FF")
        case .greenHam: return Color(hex: "#46F8A2")
        case .purpleDog: return Color(hex: "#9B6CFF")
        case .bluePenguin: return Color(hex: "#4E95FF")
        case .grayMole: return Color(hex: "#D0DAE4")
        }
    }

    /// 펫 형태 fill 색 hex (#RRGGBB, 대문자). SVG 배경 런타임 치환 및 향후 서버 hex 수신 대비.
    /// 순수 String만 반환한다(SVGView/SwiftUI 의존 없음 → watch 타겟 호환).
    var colorHex: String {
        switch self {
        case .pinkCat: return "#FD85FF"
        case .greenHam: return "#46F8A2"
        case .purpleDog: return "#9B6CFF"
        case .bluePenguin: return "#4E95FF"
        case .grayMole: return "#D0DAE4"
        }
    }

    func image(for level: Int) -> ImageResource {
        let safeLevel = min(level, 5)
        
        switch (self, safeLevel) {
        case (.pinkCat, 1): return .pinkEgg
        case (.pinkCat, 2): return .pinkLv1
        case (.pinkCat, 3): return .pinkLv2
        case (.pinkCat, 4): return .pinkLv3
        case (.pinkCat, 5): return .pinkLv4
            
        case (.greenHam, 1): return .greenEgg
        case (.greenHam, 2): return .greenLv1
        case (.greenHam, 3): return .greenLv2
        case (.greenHam, 4): return .greenLv3
        case (.greenHam, 5): return .greenLv4
            
        case (.bluePenguin, 1): return .blueEgg
        case (.bluePenguin, 2): return .blueLv1
        case (.bluePenguin, 3): return .blueLv2
        case (.bluePenguin, 4): return .blueLv3
        case (.bluePenguin, 5): return .blueLv4
            
        case (.purpleDog, 1): return .purpleEgg
        case (.purpleDog, 2): return .purpleLv1
        case (.purpleDog, 3): return .purpleLv2
        case (.purpleDog, 4): return .purpleLv3
        case (.purpleDog, 5): return .purpleLv4
            
        case (.grayMole, 1): return .grayEgg
        case (.grayMole, 2): return .grayLv1
        case (.grayMole, 3): return .grayLv2
        case (.grayMole, 4): return .grayLv3
        case (.grayMole, 5): return .grayLv4
            
        default: return .pinkEgg // 기본 이미지
        }
    }
}

