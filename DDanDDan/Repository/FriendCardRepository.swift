//
//  FriendCardRepository.swift
//  DDanDDan
//
//  Created by keone on 9/23/25.
//

import Dependencies

public struct FriendCardRepository: DependencyKey {
    var getFriendDetail: (_ userID: String) async -> Result<FriendCardEntity, NetworkError>
    var cheerFriend: (_ friendID: String) async -> Result<CheerInfo, NetworkError>
}

extension FriendCardRepository {
    public static var liveValue: FriendCardRepository {
        let userNetwork = UserNetwork()
        let cheerNetwork = CheerNetwork()
        return FriendCardRepository(
            getFriendDetail: {
                await userNetwork.fetchUserDetail(userID: $0)
            },
            cheerFriend: {
                await cheerNetwork.cheer(friendID: $0)
            }
        )
    }
}

