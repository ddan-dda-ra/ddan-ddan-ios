//
//  PathString.swift
//  DDanDDan
//
//  Created by 이지희 on 11/7/24.
//

import Foundation

enum PathString {
    enum Pet {
        static let fetchPet = "/v1/pets/"
        static let userPets = "/v1/pets/me"
        static let randomPet = "/v1/pets/me/random"
        static let randomGachaPet = "/v1/pets/me/gacha"
    }
    
    enum User {
        static let user = "/v1/users/me"
        static var userDetail = "/v1/users/"
        static let userSetting = "/v1/users/me/settings"
        static let mainPet = "/v1/users/me/main-pet"
        static let updateDailyKcal = "/v1/users/me/daily-calorie"
    }
    
    enum Auth {
        static let login = "/v1/auth/login"
        static let reissue = "/v1/auth/reissue"
    }
    
    enum Rank {
        static let rank = "/v1/ranking"
    }
  
    enum Cheer {
        static var cheerFriend = "/v1/cheers/"
    }

    enum Friend {
        static let friendsList = "/v1/friends/me"
        static let deleteFriend = "/v1/friends/"
        static let createInviteCode = "/v1/friends/invite-codes"
        static let inviteCodeInfo = "/v1/friends/invite-codes/"
        static let inviteFriend = "/v1/friends/by-invite/"

    }
}
