//
//  RankRepository.swift
//  DDanDDan
//
//  Created by 이지희 on 3/16/25.
//

import Foundation

protocol RankRepositoryProtocol {
    func getRanking(criteria: CriteriaType, period: PeriodType) async -> Result<RankInfo, NetworkError>
}

public struct RankRepository: RankRepositoryProtocol {
    private let network = RankNetwork()
    
    public func getRanking(criteria: CriteriaType, period: PeriodType) async -> Result<RankInfo, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await network.fetchRankInfo(
            accessToken: accessToken,
            criteria: criteria.rawValue,
            periodType: period.rawValue
        )
    }
}
