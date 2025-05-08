//
//  User.swift
//  DDanDDan
//
//  Created by hwikang on 10/14/24.
//

import Foundation

import Alamofire

public struct UserData: Decodable {
    var id: String
    var name: String
    var purposeCalorie: Int
    var foodQuantity: Int
    var toyQuantity: Int
}

public struct HomeUserInfo {
    var id: String
    var purposeCalorie: Int
    var foodQuantity: Int
    var toyQuantity: Int
}

public struct DailyInfo: Decodable {
    var id: String
    var userId: String
    var date: String
    var calorie: Int
}


public struct DailyUserData: Decodable {
    var user: UserData
    var dailyInfo: DailyInfo
    var rewardedFoodQuantity: Int
    var rewardedToyQuantity: Int
}

public struct UserPetData: Decodable {
    var user: UserData
    var pet: Pet
}

public struct EmptyEntity: Codable, EmptyResponse {
    public static func emptyValue() -> EmptyEntity {
        return .init()
    }
}
