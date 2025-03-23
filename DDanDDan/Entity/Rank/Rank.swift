//
//  Rank.swift
//  DDanDDan
//
//  Created by 이지희 on 3/1/25.
//

import Foundation

// MARK: - RankDTO
public struct RankInfo: Decodable, Equatable {
    let criteria, periodType: String
    let ranking: [Ranking]
    let myRanking: Ranking
}

// MARK: - Ranking
public struct Ranking: Decodable, Equatable {
    let rank: Int
    let userID, userName: String
    let mainPetType: PetType
    let petLevel, totalCalories, totalSucceededDays: Int

    enum CodingKeys: String, CodingKey {
        case rank
        case userID = "userId"
        case userName, mainPetType, petLevel, totalCalories, totalSucceededDays
    }
    
     public static func == (lhs: Ranking, rhs: Ranking) -> Bool {
        return lhs.rank == rhs.rank
    }
}


public enum CriteriaType: String {
    case TOTAL_CALORIES = "TOTAL_CALORIES"
    case TOTAL_SUCCEEDED_DAYS = "TOTAL_SUCCEEDED_DAYS"
}

public enum PeriodType: String {
    case DAILY = "DAILY"
    case WEEKLY = "WEEKLY"
    case MONTHLY = "MONTHLY"
    case YEARLY = "YEARLY"
}
