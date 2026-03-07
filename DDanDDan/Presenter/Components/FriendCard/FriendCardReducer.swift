//
//  FriendCardReducer.swift
//  DDanDDan
//
//  Created by keone on 9/13/25.
//

import ComposableArchitecture
import SwiftUI
import Dependencies

@Reducer
struct FriendCardReducer {
    @Dependency(\.friendCardRepository) var repository: FriendCardRepository
    
    enum CardType: Equatable {
        case cheer
        case invite(user: AddedFriend)
        case pendingInvite(code: String)
    }
    
    @ObservableState
    struct State: Equatable {
        let userID: String
        var entity: FriendCardEntity?
        let type: CardType
        var toastMessage: String = ""
        var dismiss: Bool = false
        var fireAnimation: Bool = false
        var showToast: Bool {
            !toastMessage.isEmpty
        }
        var petLottieStrng: String {
            guard let entity else { return "" }
            return entity.mainPet.type.lottieString(level: entity.mainPet.level)
        }
        var petBackgroundImage: Image {
            guard let entity else { return Image(uiImage: UIImage()) }
            return entity.mainPet.type.cardBackgroundImage
        }
        var hideButton: Bool {
            switch type {
            case .cheer:
                entity?.isFriend == false || entity?.isCheeredToday == true || UserDefaultValue.userId == entity?.userId
            case .invite: false
            case .pendingInvite: false
            }
        }
        var buttonTitle: String {
            switch type {
            case .cheer: "응원하기"
            case .invite: "친구하기"
            case .pendingInvite: "친구하기"
            }
        }

        var isAddingFriend: Bool = false

        var badgeTitle: String? {
            if UserDefaultValue.userId == entity?.userId {
                "나"
            } else if entity?.isFriend == true {
                "친구"
            } else {
                nil
            }
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        case onAppear
        case setEntity(FriendCardEntity)
        case setErrorMessage(String)
        case onTapButton
        case onCheerSuccess
        case setDismiss
        case inviteResult(TaskResult<AddedFriend>)
        case addFriendResult(Result<AddedFriend, NetworkError>)
        case endFireAnimation
        
        case delegate(Delegate)
        
        enum Delegate {
            case dismissAndNavigateToFriendAdd(AddedFriend)
            case dismiss
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                switch state.type {
                case .cheer:
                    return fetchUserDetail(userID: state.userID)
                case let .invite(user: user):
                    return fetchUserDetail(userID: user.friendUser.id)
                case let .pendingInvite(code: code):
                    return fetchInviteCodeInfo(code: code)
                }

            case .onTapButton:
                switch state.type {
                case .cheer:
                    return cheerFriend(userID: state.userID)
                case .invite(let user):
                    return .send(.delegate(.dismissAndNavigateToFriendAdd(user)))
                case .pendingInvite(let code):
                    state.isAddingFriend = true
                    return addFriend(code: code)
                }
                
            case let .inviteResult(result):
                switch result {
                case .success(let response):
                    return .none
                case .failure(let error):
                    print(error.localizedDescription)
                    return .none
                }

            case let .addFriendResult(result):
                state.isAddingFriend = false
                switch result {
                case .success(let addedFriend):
                    return .send(.delegate(.dismissAndNavigateToFriendAdd(addedFriend)))
                case .failure(let error):
                    switch error {
                    case .serverError(_, let code):
                        switch code {
                        case "FR001":
                            return showToast(&state, message: "이미 친구입니다.")
                        case "FR002":
                            return showToast(&state, message: "존재하지 않는 초대 코드입니다.")
                        case "FR003":
                            return showToast(&state, message: "자기 자신을 친구로 추가할 수 없습니다.")
                        case "FR004":
                            return showToast(&state, message: "친구 요청이 실패했습니다.")
                        case "IC004":
                            return showToast(&state, message: "자신의 초대코드는 사용할 수 없습니다.")
                        default:
                            return showToast(&state, message: "친구 추가에 실패했습니다.")
                        }
                    default:
                        return showToast(&state, message: "친구 추가에 실패했습니다.")
                    }
                }
                
            case .delegate:
                return .none
                
            case .binding:
                return .none
                
            case .setDismiss:
                state.dismiss = true
                return .send(.delegate(.dismiss))
                
            case let .setEntity(entity):
                state.entity = entity
                return .none
                
            case let .setErrorMessage(message):
                return showToast(&state, message: message)
                
            case .onCheerSuccess:
                state.entity?.isCheeredToday = true
                state.fireAnimation = true
                state.entity?.monthlyReceivedCheerCount += 1
                return performFireAnimation()
                
            case .endFireAnimation:
                state.fireAnimation = false
                return .none
            }
        }
    }
    
    private func fetchUserDetail(userID: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.getFriendDetail(userID)
            switch result {
            case .success(let entity):
                await send(.setEntity(entity))
            case .failure:
                await send(.setDismiss)
            }
        }
    }
    
    private func fetchInviteCodeInfo(code: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.fetchInviteCodeInfo(code)
            switch result {
            case .success(let info):
                let entity = FriendCardEntity(
                    userId: info.inviterUser.id,
                    userName: info.inviterUser.name,
                    mainPet: .init(
                        id: "",
                        type: info.inviterUser.mainPetType,
                        level: info.inviterUser.petLevel,
                        expPercent: 0
                    ),
                    todayCalorie: 0,
                    monthlyReceivedCheerCount: 0,
                    isFriend: false,
                    isCheeredToday: false
                )
                await send(.setEntity(entity))
            case .failure:
                await send(.setDismiss)
            }
        }
    }

    private func addFriend(code: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.addFriend(code)
            await send(.addFriendResult(result))
        }
    }

    private func cheerFriend(userID: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.cheerFriend(userID)
            switch result {
            case .success:
                await send(.onCheerSuccess)
            case .failure(let error):
                await send(.setErrorMessage(error.description))
            }
        }
    }
    
    func showToast(_ state: inout State, message: String) -> Effect<Action> {
        state.toastMessage = message
        
        return .run { send in
            try await Task.sleep(nanoseconds: 2_500_000_000)
            await send(.setErrorMessage(""))
        }
    }
    
    private func performFireAnimation() -> Effect<Action> {
        return .run { send in
            try await Task.sleep(for: .seconds(2.0))
            await send(.endFireAnimation)
        }
    }
}
