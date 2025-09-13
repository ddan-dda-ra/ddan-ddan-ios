//
//  FriendCardReducer.swift
//  DDanDDan
//
//  Created by keone on 9/13/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct FriendCardReducer {
    
    enum CardType {
        case cheer
        case invite
    }
    
    @ObservableState
    struct State: Equatable {
        let entity: FriendCardEntity
        let type: CardType
        var buttonTitle: String {
            switch type {
            case .cheer: "응원하기"
            case .invite: "친구하기"
            }
        }
        
        var badgeTitle: String? {
            if UserDefaultValue.userId == entity.userID {
                "나"
            } else if entity.isFriend {
                "친구"
            } else {
                nil
            }
        }
    }
    enum Action {
        
    }
}
