//
//  Friend.swift
//  DDanDDan
//
//  Created by 이지희 on 9/23/25.
//

import Foundation

// MARK: - FriendList
public struct FriendList: Decodable {
    let friends: [Friend]
    let totalCount: Int
}

public struct Friend: Decodable {
    let id: String
    let name: String
    let mainPetType: PetType
    let petLevel: Int
}
