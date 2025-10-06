//
//  FriendCardRepository.swift
//  DDanDDan
//
//  Created by keone on 9/23/25.
//

import Dependencies

public struct FriendCardRepository: DependencyKey {
    var getRanking: (_ userID: String) async -> Result<FriendCardEntity, NetworkError>
    var getFriendDetail: (_ userID: String) async -> Result<FriendCardEntity, NetworkError>
    var cheerFriend: (_ friendID: String) async -> Result<CheerInfo, NetworkError>
    var addFriend: (_ inviteCode: String) async -> Result<AddedFriend, NetworkError>
}

extension FriendCardRepository {
    public static var liveValue: FriendCardRepository {
        let userNetwork = UserNetwork()
        let cheerNetwork = CheerNetwork()
        let friendNetwork = FriendNetwork()
        
        return FriendCardRepository(
            getRanking: {
                await userNetwork.fetchUserDetail(userID: $0)
            },
            getFriendDetail: {
                await userNetwork.fetchUserDetail(userID: $0)
            },
            cheerFriend: {
                await cheerNetwork.cheer(friendID: $0)
            },
            addFriend: {
                guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
                return await friendNetwork.addFriend(accessToken: accessToken, inviteCode: $0)
            }
        )
    }
}

