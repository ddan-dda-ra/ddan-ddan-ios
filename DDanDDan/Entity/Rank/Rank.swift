//
//  Rank.swift
//  DDanDDan
//
//  Created by 이지희 on 3/1/25.
//

import Foundation


struct CachedRankInfo: Codable, Equatable {
    let kcalRanking: RankInfo
    let goalRanking: RankInfo
    
    static var cacheKey: String {
        return "cached_ranking_data"
    }
}


// MARK: - RankDTO
public struct RankInfo: Codable, Equatable {
    let criteria, periodType: String
    let ranking: [Ranking]
    let myRanking: Ranking
    
    
}

// MARK: - Ranking
public struct Ranking: Codable, Equatable, Identifiable {
    public var id: String { userID }
    
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
         return lhs.userID == rhs.userID && lhs.totalCalories == rhs.totalCalories && lhs.totalSucceededDays == rhs.totalSucceededDays
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

// MARK: - Ranking View Data
struct TabRanking: Equatable {
    let kcal: RankInfo
    let goal: RankInfo
}

