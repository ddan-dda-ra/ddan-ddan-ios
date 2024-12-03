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
    func lottieString(level: Int, mode: LottieMode = .normal) -> String {
        switch (self, level, mode) {
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
            
            //            // bluePenguin Lottie
            //            case (.bluePenguin, 1, .normal): return LottieString.penguin.lv1.normal
            //            case (.bluePenguin, 1, .eatPlay): return LottieString.penguin.lv1.eat_play
            //            case (.bluePenguin, 2, .normal): return LottieString.penguin.lv2.normal
            //            case (.bluePenguin, 2, .eatPlay): return LottieString.penguin.lv2.eat_play
            //            case (.bluePenguin, 3, .normal): return LottieString.penguin.lv3.normal
            //            case (.bluePenguin, 3, .eatPlay): return LottieString.penguin.lv3.eat_play
            //            case (.bluePenguin, 4, .normal): return LottieString.penguin.lv4.normal
            //            case (.bluePenguin, 4, .eatPlay): return LottieString.penguin.lv4.eat_play
            //            case (.bluePenguin, 5, .normal): return LottieString.penguin.lv5.normal
            //            case (.bluePenguin, 5, .eatPlay): return LottieString.penguin.lv5.eat_play
            //
            //            // purpleDog Lottie
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
