//
//  FriendCard.swift
//  DDanDDan
//
//  Created by keone on 9/13/25.
//


public struct FriendCardEntity: Decodable, Equatable {
    let userId: String
    let userName: String
    let mainPet: Pet
    let todayCalorie: Int
    var monthlyReceivedCheerCount: Int
    let isFriend: Bool
    var isCheeredToday: Bool
}
