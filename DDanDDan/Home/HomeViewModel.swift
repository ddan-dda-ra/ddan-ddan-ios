//
//  HomeViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI

class HomeViewModel: ObservableObject {
  let model: HomeModel
  
  init(model: HomeModel) {
    self.model = model
  }
  
  /// Returns the correct background image based on the petType
  func backgroundImage() -> Image {
    switch model.petType {
    case .pinkCat:
      return Image(.pinkBackground).resizable()
    case .greenHam:
      return Image(.greenBackground).resizable()
    case .purpleDog:
      return Image(.purpleBackground).resizable()
    case .bluePenguin:
      return Image(.blueBackground).resizable()
    }
  }
  
  /// Returns the correct character image based on the petType and level
  func characterImage() -> Image {
    switch (model.petType, model.level) {
    case (.pinkCat, 1):
      return Image(.pinkEgg).resizable()
    case (.pinkCat, 2):
      return Image(.pinkLv1).resizable()
    case (.pinkCat, 3):
      return Image(.pinkLv2).resizable()
    case (.pinkCat, 4):
      return Image(.pinkLv3).resizable()
    case (.pinkCat, 5):
      return Image(.pinkLv4).resizable()
    case (.greenHam, 1):
      return Image(.greenEgg).resizable()
    case (.greenHam, 2):
      return Image(.greenLv1).resizable()
    case (.greenHam, 3):
      return Image(.greenLv2).resizable()
    case (.greenHam, 4):
      return Image(.greenLv3).resizable()
    case (.greenHam, 5):
      return Image(.greenLv4).resizable()
    case (.bluePenguin, 1):
      return Image(.blueEgg).resizable()
    case (.bluePenguin, 2):
      return Image(.blueLv1).resizable()
    case (.bluePenguin, 3):
      return Image(.blueLv2).resizable()
    case (.bluePenguin, 4):
      return Image(.blueLv3).resizable()
    case (.bluePenguin, 5):
      return Image(.blueLv4).resizable()
    case (.purpleDog, 1):
      return Image(.purpleEgg).resizable()
    case (.purpleDog, 2):
      return Image(.purpleLv1).resizable()
    case (.purpleDog, 3):
      return Image(.purpleLv2).resizable()
    case (.purpleDog, 4):
      return Image(.purpleLv3).resizable()
    case (.purpleDog, 5):
      return Image(.purpleLv4).resizable()
    default:
      return Image(.pinkEgg).resizable() // Default character
    }
  }
}
