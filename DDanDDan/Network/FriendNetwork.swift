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
    
    public func deleteFriend(accessToken: String, friendId: String) async -> Result<EmptyEntity, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        return await manager.request(
            url: PathString.Friend.deleteFirend + friendId,
            method: .delete,
            headers: headers
        )
    }
}
