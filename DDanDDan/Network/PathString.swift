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
    }
    
    enum User {
        static let user = "/v1/user/me"
        static let mainPet = "/v1/user/me/main-pet"
        static let updateDailyKcal = "/v1/user/me/daily-calorie"
    }
    
    enum Auth {
        static let reissue = "/v1/auth/reissue"
    }
}
