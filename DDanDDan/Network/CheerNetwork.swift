//
//  CheerNetwork.swift
//  DDanDDan
//
//  Created by keone on 9/26/25.
//


import Alamofire

public struct CheerNetwork {
    private let manager = NetworkManager()
    
    // MARK: - GET
    public func cheer(friendID: String) async -> Result<CheerInfo, NetworkError> {
        
        return await manager.request(
            url: PathString.Cheer.cheerFriend + friendID,
            method: .post
        )
    }
}
