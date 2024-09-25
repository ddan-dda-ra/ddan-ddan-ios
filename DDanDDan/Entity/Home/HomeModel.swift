//
//  HomeModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import Foundation

struct HomeModel {
  let petType: PetType
  let goalKcal: Int
  let currentKcal: Int
  let level: Int
  let feedCount: Int
  let toyCount: Int
}


enum PetType {
  case pinkCat
  case greenHam
  case purpleDog
  case bluePenguin
}
