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
            }
        }
        var buttonTitle: String {
            switch type {
            case .cheer: "응원하기"
            case .invite: "친구하기"
            }
        }
        
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
        
        case delegate(Delegate)
        
        enum Delegate {
            case dismissAndNavigateToFriendAdd(AddedFriend)
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
                }
                
            case .onTapButton:
                switch state.type {
                case .cheer:
                    return cheerFriend(userID: state.userID)
                case .invite(let user):
                    return .send(.delegate(.dismissAndNavigateToFriendAdd(user)))
                }
                
            case let .inviteResult(result):
                switch result {
                case .success(let response):
                    print(response)
                    return .none
                case .failure(let error):
                    print(error.localizedDescription)
                    return .none
                }
                
            case .delegate:
                return .none
                
            case .binding:
                return .none
                return fetchUserDetail(userID: state.userID)
            case .setDismiss:
                state.dismiss = true
            case let .setEntity(entity):
                state.entity = entity
            case let .setErrorMessage(message):
                return showToast(&state, message: message)
            case .onCheerSuccess:
                state.entity?.isCheeredToday = true
                state.fireAnimation = true
            }
            
            return .none
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
    
    private func acceptInvite(code: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.addFriend(code)
            switch result {
            case .success(let entity):
                await send(.inviteResult(.success(entity)))
            case .failure(let error):
                await send(.inviteResult(.failure(error)))
            }
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
    
}
