//
//  Friend.swift
//  DDanDDan
//
//  Created by 이지희 on 9/23/25.
//

import Foundation

// MARK: - FriendList
public struct FriendList: Decodable {
    public let friends: [Friend]
    public let totalCount: Int
}

public struct Friend: Decodable, Equatable {
    public let id: String
    public let name: String
    public let mainPetType: PetType
    public let petLevel: Int
}

public struct InviteCode: Decodable, Equatable {
    public let code: String
    public let expiresAt: String
    public let createdAt: String
}
