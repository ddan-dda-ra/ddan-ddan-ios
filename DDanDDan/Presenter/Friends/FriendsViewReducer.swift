//
//  FriendsViewReducer.swift
//  DDanDDan
//
//  Created by 이지희 on 9/23/25.
//


import Foundation

import ComposableArchitecture

@Reducer
struct FriendsViewReducer {
    let repository = FriendRepository()
    
    @ObservableState
    struct State: Equatable {
        var friendsList: [FriendModel] = []
        var isLoading = false
        var errorMessage: String?
    }
    
    enum Action {
        case onAppear
        case friendsListResponse(Result<FriendList, NetworkError>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return loadFriendsList()
                
            case let .friendsListResponse(.success(friendsList)):
                state.isLoading = false
                state.friendsList = friendsList.friends.map({ friend in
                        .init(name: friend.name, petType: friend.mainPetType, level: friend.petLevel)
                })
                state.errorMessage = nil
                return .none
                
            case let .friendsListResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}

extension FriendsViewReducer {
    func loadFriendsList() -> Effect<Action> {
        return .run { send in
            await send(.friendsListResponse(
                await repository.getFriendList()
            ))
        }
    }
}
