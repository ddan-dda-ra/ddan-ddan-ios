//
//  RankNetwork.swift
//  DDanDDan
//
//  Created by 이지희 on 3/1/25.
//

import Foundation

import Alamofire

public struct RankNetwork {
    private let manager = NetworkManager()
    
    // MARK: - GET
    public func fetchRankInfo(accessToken: String, criteria: String, periodType: String) async -> Result<RankInfo, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        let parameters: Parameters = [
            "criteria": criteria,
            "periodType": periodType
        ]
        
        return await manager.request(
            url: PathString.Rank.rank + "",
            method: .get,
            headers: headers,
            parameters: parameters,
            encoding: URLEncoding.queryString
        )
    }
}
