//
//  FriendRepository.swift
//  DDanDDan
//
//  Created by 이지희 on 9/23/25.
//

import Foundation

public protocol FriendRepositoryProtocol {
    func getFriendList() async -> Result<FriendList, NetworkError>
    func deleteFriend(_ friendId: String) async -> Result<EmptyEntity, NetworkError>
}

public struct FriendRepository: FriendRepositoryProtocol {
    private let network = FriendNetwork()
    
    public func getFriendList() async -> Result<FriendList, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await network.fetchFriendList(accessToken: accessToken)
    }
    
    public func deleteFriend(_ friendId: String) async -> Result<EmptyEntity, NetworkError>  {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await network.deleteFriend(accessToken: accessToken, friendId: friendId)
    }
}
