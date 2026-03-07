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
    @ObservableState
    struct State: Equatable {
        var selectedTab: TabType = .home
        var navigateToFriendAdd: AddedFriend? = nil
        
        var showToast: Bool = false
        var toastMessage: String = ""
        
        var rankState = RankViewReducer.State()
        var friendsState = FriendsViewReducer.State()
        var settingState = SettingViewReducer.State()
        
        // Scope
        @Presents var friendCard: FriendCardReducer.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case handleDeepLink(inviteCode: String)
        case clearNavigateToFriendAdd

        case rank(RankViewReducer.Action)
        case friends(FriendsViewReducer.Action)
        case setting(SettingViewReducer.Action)

        // Scope
        case friendCard(PresentationAction<FriendCardReducer.Action>)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.rankState, action: \.rank) {
            RankViewReducer(repository: RankRepository())
        }
        
        Scope(state: \.friendsState, action: \.friends) {
            FriendsViewReducer()
        }
        
        Scope(state: \.settingState, action: \.setting) {
            SettingViewReducer(repository: SettingRepository())
        }
        
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
                state.friendCard = FriendCardReducer.State(
                    userID: "",
                    type: .pendingInvite(code: inviteCode)
                )
                return .none
                
            case .clearNavigateToFriendAdd:
                state.navigateToFriendAdd = nil
                return .none
                
            case .binding:
                return .none
                
            case .rank(.friendCard(.presented(.delegate(.dismiss)))):
                state.rankState.friendCard = nil
                return .none

            case .friends(.friendCard(.presented(.delegate(.dismiss)))):
                state.friendsState.friendCard = nil
                return .none
                
            // 각 탭의 Action은 해당 Reducer에서 처리
            case .rank, .friends, .setting:
                return .none
            }
        }
        .ifLet(\.$friendCard, action: \.friendCard) {
            FriendCardReducer()
        }
    }
    
}
