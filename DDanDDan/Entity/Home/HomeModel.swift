//
//  HomeModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI

struct HomeModel {
    var petType: PetType
    var level: Int
    var exp: Double
    var goalKcal: Int
    var feedCount: Int
    var toyCount: Int
}

enum LottieMode {
    case normal
    case eatPlay
}

extension PetType {
    var backgroundImage: Image {
        switch self {
        case .pinkCat: return Image(.pinkBackground).resizable()
        case .greenHam: return Image(.greenBackground).resizable()
        case .purpleDog: return Image(.purpleBackground).resizable()
        case .bluePenguin: return Image(.blueBackground).resizable()
        case .grayMole: return Image(.grayBackground).resizable()
        }
    }
    
    var seBackgroundImage: Image {
        switch self {
        case .pinkCat: return Image(.seBgPink).resizable()
        case .greenHam: return Image(.seBgGreen).resizable()
        case .purpleDog: return Image(.seBgPurple).resizable()
        case .bluePenguin: return Image(.seBgBlue).resizable()
        case .grayMole: return Image(.seBgGray).resizable()
        }
    }
    
    var cardBackgroundImage: Image {
        switch self {
        case .pinkCat: return Image(.catCardBackground).resizable()
        case .greenHam: return Image(.hamsterCardBackground).resizable()
        case .purpleDog: return Image(.dogCardBackground).resizable()
        case .bluePenguin: return Image(.penguinCardBackground).resizable()
        case .grayMole: return Image(.moleCardBackground).resizable()
        }
    }
    
    func lottieString(level: Int, mode: LottieMode = .normal) -> String {
        let safeLevel = min(level, 5)
        
        switch (self, safeLevel, mode) {
            // pinkCat Lottie
        case (.pinkCat, 1, .normal): return LottieString.cat.lv1.normal
        case (.pinkCat, 1, .eatPlay): return LottieString.cat.lv1.eatPlay
        case (.pinkCat, 2, .normal): return LottieString.cat.lv2.normal
        case (.pinkCat, 2, .eatPlay): return LottieString.cat.lv2.eatPlay
        case (.pinkCat, 3, .normal): return LottieString.cat.lv3.normal
        case (.pinkCat, 3, .eatPlay): return LottieString.cat.lv3.eatPlay
        case (.pinkCat, 4, .normal): return LottieString.cat.lv4.normal
        case (.pinkCat, 4, .eatPlay): return LottieString.cat.lv4.eatPlay
        case (.pinkCat, 5, .normal): return LottieString.cat.lv5.normal
        case (.pinkCat, 5, .eatPlay): return LottieString.cat.lv5.eatPlay
            
            // greenHam Lottie
        case (.greenHam, 1, .normal): return LottieString.hamster.lv1.normal
        case (.greenHam, 1, .eatPlay): return LottieString.hamster.lv1.eatPlay
        case (.greenHam, 2, .normal): return LottieString.hamster.lv2.normal
        case (.greenHam, 2, .eatPlay): return LottieString.hamster.lv2.eatPlay
        case (.greenHam, 3, .normal): return LottieString.hamster.lv3.normal
        case (.greenHam, 3, .eatPlay): return LottieString.hamster.lv3.eatPlay
        case (.greenHam, 4, .normal): return LottieString.hamster.lv4.normal
        case (.greenHam, 4, .eatPlay): return LottieString.hamster.lv4.eatPlay
        case (.greenHam, 5, .normal): return LottieString.hamster.lv5.normal
        case (.greenHam, 5, .eatPlay): return LottieString.hamster.lv5.eatPlay
            
            // bluePenguin Lottie
        case (.bluePenguin, 1, .normal): return LottieString.penguin.lv1.normal
        case (.bluePenguin, 1, .eatPlay): return LottieString.penguin.lv1.eatPlay
        case (.bluePenguin, 2, .normal): return LottieString.penguin.lv2.normal
        case (.bluePenguin, 2, .eatPlay): return LottieString.penguin.lv2.eatPlay
        case (.bluePenguin, 3, .normal): return LottieString.penguin.lv3.normal
        case (.bluePenguin, 3, .eatPlay): return LottieString.penguin.lv3.eatPlay
        case (.bluePenguin, 4, .normal): return LottieString.penguin.lv4.normal
        case (.bluePenguin, 4, .eatPlay): return LottieString.penguin.lv4.eatPlay
        case (.bluePenguin, 5, .normal): return LottieString.penguin.lv5.normal
        case (.bluePenguin, 5, .eatPlay): return LottieString.penguin.lv5.eatPlay
            
            // purpleDog Lottie
        case (.purpleDog, 1, .normal): return LottieString.puppy.lv1.normal
        case (.purpleDog, 1, .eatPlay): return LottieString.puppy.lv1.eatPlay
        case (.purpleDog, 2, .normal): return LottieString.puppy.lv2.normal
        case (.purpleDog, 2, .eatPlay): return LottieString.puppy.lv2.eatPlay
        case (.purpleDog, 3, .normal): return LottieString.puppy.lv3.normal
        case (.purpleDog, 3, .eatPlay): return LottieString.puppy.lv3.eatPlay
        case (.purpleDog, 4, .normal): return LottieString.puppy.lv4.normal
        case (.purpleDog, 4, .eatPlay): return LottieString.puppy.lv4.eatPlay
        case (.purpleDog, 5, .normal): return LottieString.puppy.lv5.normal
        case (.purpleDog, 5, .eatPlay): return LottieString.puppy.lv5.eatPlay
            
        case (.grayMole, 1, .normal): return LottieString.mole.lv1.normal
        case (.grayMole, 1, .eatPlay): return LottieString.mole.lv1.eatPlay
        case (.grayMole, 2, .normal): return LottieString.mole.lv2.normal
        case (.grayMole, 2, .eatPlay): return LottieString.mole.lv2.eatPlay
        case (.grayMole, 3, .normal): return LottieString.mole.lv3.normal
        case (.grayMole, 3, .eatPlay): return LottieString.mole.lv3.eatPlay
        case (.grayMole, 4, .normal): return LottieString.mole.lv4.normal
        case (.grayMole, 4, .eatPlay): return LottieString.mole.lv4.eatPlay
        case (.grayMole, 5, .normal): return LottieString.mole.lv5.normal
        case (.grayMole, 5, .eatPlay): return LottieString.mole.lv5.eatPlay
            
        default: return LottieString.cat.lv1.normal
        }
    }
}

struct ListItem {
    let image: Image
    let title: String
    let content: String
}

enum bubbleTextType {
    case success
    case failure
    case normal
    case eat
    case play
    
    func getRandomText() -> [ImageResource] {
        switch self {
        case .success:
            return [.success1, .success2, .success3]
        case .failure:
            return [.failure1, .failure2, .failure3]
        case .normal:
            return [.default1, .default2, .default3]
        case .eat:
            return [.eat1, .eat2, .eat3]
        case .play:
            return [.play1, .play2, .play3]
        }
    }
}
