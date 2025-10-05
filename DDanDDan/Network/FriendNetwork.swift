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
            url: PathString.Friend.friendsList,
            method: .get,
            headers: headers
        )
    }
    
    // MARK: - POST
    public func createInviteCode(accessToken: String) async -> Result<InviteCode, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        return await manager.request(
            url: PathString.Friend.createInviteCode,
            method: .post,
            headers: headers
            )
    }
    
    // MARK: - DELETE
    public func deleteFriend(accessToken: String, friendId: String) async -> Result<EmptyEntity, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        return await manager.request(
            url: PathString.Friend.deleteFriend + friendId,
            method: .delete,
            headers: headers
        )
    }
}
