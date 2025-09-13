//
//  FriendCard.swift
//  DDanDDan
//
//  Created by keone on 9/13/25.
//

struct FriendCardEntity: Equatable {
    let userID: String
    let userName: String
    let mainPetType: PetType
    let petLevel: Int
    let totalCalories: Int
    let cheerCount: Int
    let isFriend: Bool
}
