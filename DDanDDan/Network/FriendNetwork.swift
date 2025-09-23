//
//  FriendNetwork.swift
//  DDanDDan
//
//  Created by 이지희 on 9/23/25.
//

import Foundation
import Alamofire

public struct FriendNetwork {
    private let manager = NetworkManager()
    
    // MARK: - GET
    public func fetchFriendList(accessToken: String) async -> Result<FriendList, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        return await manager.request(
            url: PathString.Friend.friendsList + "",
            method: .get,
            headers: headers
        )
    }
}
