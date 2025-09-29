//
//  FriendCardRepository.swift
//  DDanDDan
//
//  Created by keone on 9/23/25.
//

import Dependencies

public struct FriendCardRepository: DependencyKey {
    var getRanking: (_ userID: String) async -> Result<FriendCardEntity, NetworkError>
}

extension FriendCardRepository {
    public static var liveValue: FriendCardRepository {
        let network = UserNetwork()
        return FriendCardRepository(
            getRanking: {
                await network.fetchUserDetail(userID: $0)
            }
        )
    }
}

