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
    enum CardType {
        case cheer
        case invite
    }
    
    @ObservableState
    struct State: Equatable {
        let userID: String
        var entity: FriendCardEntity?
        let type: CardType
      
        var petLottieStrng: String {
            guard let entity else { return "" }
            return entity.mainPet.type.lottieString(level: entity.mainPet.level)
        }
        var petBackgroundImage: Image {
            guard let entity else { return Image(uiImage: UIImage()) }
            return entity.mainPet.type.cardBackgroundImage
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
    enum Action {
        case onAppear
        case entityResult(TaskResult<FriendCardEntity>)
        case onTapButton
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return fetchUserDetail(userID: state.userID)
            case let .entityResult(result):
                switch result {
                case .success(let entity):
                    state.entity = entity
                case .failure(let error):
                    //TOOD: 에러 처리
                    return .none
                }
            case .onTapButton:
                switch state.type {
                case .cheer:
                    //TODO: 응원하기
                    return .none
                case .invite:
                    //TODO: 초대하기
                    return .none
                }
            }
            return .none
        }
    }
    
    private func fetchUserDetail(userID: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.getRanking(userID)
            switch result {
            case .success(let entity):
                await send(.entityResult(.success(entity)))
            case .failure(let error):
                await send(.entityResult(.failure(error)))
            }
        }
    }
}
