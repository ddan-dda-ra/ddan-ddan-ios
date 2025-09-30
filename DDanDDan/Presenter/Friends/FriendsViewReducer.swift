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
        var friendsList: [Friend] = []
        var isLoading = false
        var errorMessage: String?
        var myProfilePet: ProfileModel = .init(
            name: UserDefaultValue.nickName,
            petType: PetType(rawValue: UserDefaultValue.petType) ?? .pinkCat,
            level: UserDefaultValue.level
        )
    }
    
    enum Action {
        case onAppear
        case friendsListResponse(Result<FriendList, NetworkError>)
        case myProfileLoaded(ProfileModel)
        case deleteFriend(id: String)
        case deleteFriendResponse(id: String, Result<EmptyEntity, NetworkError>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .merge(
                    loadFriendsList(),
                    loadMyProfile()
                )
                
            case let .friendsListResponse(.success(friendsList)):
                state.isLoading = false
                state.friendsList = friendsList.friends
                state.errorMessage = nil
                return .none
                
            case let .friendsListResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .myProfileLoaded(profile):
                state.myProfilePet = profile
                return .none
                
            case let .deleteFriend(id):
                return deleteFriend(id: id)
                
            case let .deleteFriendResponse(id, .success):
                state.friendsList.removeAll { $0.id == id }
                return .none
                
            case let .deleteFriendResponse(_, .failure(error)):
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
    
    func loadMyProfile() -> Effect<Action> {
        return .run { send in
            let profile = ProfileModel(
                name: UserDefaultValue.nickName,
                petType: PetType(rawValue: UserDefaultValue.petType) ?? .pinkCat,
                level: UserDefaultValue.level
            )
            await send(.myProfileLoaded(profile))
        }
    }
    
    func deleteFriend(id: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.deleteFriend(id)
            await send(.deleteFriendResponse(id: id, result))
        }
    }
}
