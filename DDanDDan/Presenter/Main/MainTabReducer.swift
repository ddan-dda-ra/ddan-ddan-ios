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
        
        var rankState = RankViewReducer.State()
        var friendsState = FriendsViewReducer.State()
        var settingState = SettingViewReducer.State()
        
        // Scope
        @Presents var friendCard: FriendCardReducer.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case handleDeepLink(inviteCode: String)
        case addFriendResult(Result<AddedFriend, NetworkError>)
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
                state.isProcessingDeepLink = true
                return addFriend(code: inviteCode)
                
            case let .addFriendResult(result):
                state.isProcessingDeepLink = false
                
                switch result {
                case .success(let addedFriend):
                    state.friendCard = FriendCardReducer.State(
                        userID: "",
                        type: .invite(user: addedFriend)
                    )
                    return .none
                    
                case .failure(let error):
                    state.showToast = true
                    print(error)
                    switch error {
                    case .serverError(_, let code):
                        switch code {
                        case "FR001":
                            state.toastMessage = "이미 친구입니다."
                        case "FR002":
                            state.toastMessage = "존재하지 않는 초대 코드입니다."
                        case "FR003":
                            state.toastMessage = "자기 자신을 친구로 추가할 수 없습니다."
                        case "FR004":
                            state.toastMessage = "친구 요청이 실패했습니다."
                        case "IC004":
                            state.toastMessage = "자신의 초대코드는 사용할 수 없습니다."
                        default:
                            state.toastMessage = "친구 추가에 실패했습니다."
                        }
                    case .invalidResponse:
                        state.toastMessage = "서버 응답이 올바르지 않습니다."
                    default:
                        state.toastMessage = "친구 추가에 실패했습니다."
                    }
                    
                    return .none
                }
                
            case .clearNavigateToFriendAdd:
                state.navigateToFriendAdd = nil
                return .none
                
            case .binding:
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
