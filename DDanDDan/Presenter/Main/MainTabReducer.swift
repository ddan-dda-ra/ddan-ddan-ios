//
//  MainTabReducer.swift
//  DDanDDan
//
//  Created by 이지희 on 10/5/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct MainTabReducer {
    @Dependency(\.friendCardRepository) var repository: FriendCardRepository
    
    @ObservableState
    struct State: Equatable {
        var selectedTab: TabType = .home
        var isProcessingDeepLink: Bool = false
        var navigateToFriendAdd: AddedFriend? = nil
        
        var showToast: Bool = false
        var toastMessage: String = ""
        // Scope
        @Presents var friendCard: FriendCardReducer.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case handleDeepLink(inviteCode: String)
        case addFriendResult(TaskResult<AddedFriend>)
        case navigateToFriendDetail(AddedFriend)
        case clearNavigateToFriendAdd
        //Scope
        case friendCard(PresentationAction<FriendCardReducer.Action>)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .friendCard(.presented(.delegate(.dismissAndNavigateToFriendAdd(let user)))):
                state.friendCard = nil
                state.navigateToFriendAdd = user
                state.selectedTab = .friends
                return .none
                
                
            case .friendCard:
                return .none
                
            case let .handleDeepLink(inviteCode):
                state.isProcessingDeepLink = true
                return addFriend(code: inviteCode)
            case let .addFriendResult(result):
                state.isProcessingDeepLink = false
                
                switch result {
                case .success(let addedFriend):
                    state.friendCard = FriendCardReducer.State(
                        userID: "", type: .invite(user: addedFriend)
                    )
                    return .none
                    
                case .failure(let error):
                    state.showToast = true
                    state.toastMessage = "이미 친구입니다."
                    return .none
                }
                
            case .navigateToFriendDetail:
                return .none
                
            case .clearNavigateToFriendAdd:
                 state.navigateToFriendAdd = nil
                 return .none
                
            case .binding:
                return .none
            }
        }
        .ifLet(\.$friendCard, action: \.friendCard) {
            FriendCardReducer()
        }
    }
    
    private func addFriend(code: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.addFriend(code)
            switch result {
            case .success(let friend):
                await send(.addFriendResult(.success(friend)))
            case .failure(let error):
                await send(.addFriendResult(.failure(error)))
            }
        }
    }
}
