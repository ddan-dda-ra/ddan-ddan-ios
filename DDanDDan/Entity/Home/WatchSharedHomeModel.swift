//
//  WatchSharedHomeModel.swift
//  DDanDDan
//
//  Created by 이지희 on 11/30/24.
//

import SwiftUI

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
    
    var color: Color  {
        switch self {
        case .pinkCat: return .pinkGraphics
        case .greenHam: return .greenGraphics
        case .purpleDog: return .purpleGraphics
        case .bluePenguin: return .blueGraphics
        }
    }
    
    func image(for level: Int) -> ImageResource {
        switch (self, level) {
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
            
        default: return .blueEgg // 기본 이미지
        }
    }
}


