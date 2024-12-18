//
//  UpdateCalorieViewModel.swift
//  DDanDDan
//
//  Created by hwikang on 9/26/24.
//

import Foundation
import ComposableArchitecture

struct UpdateCalorieReducer: Reducer {
    private let repository: SettingRepositoryProtocol
    private let userNickname = UserDefaultValue.nickName
    
    public init(repository: SettingRepositoryProtocol) {
        self.repository = repository
    }
    
    struct State: Equatable {
        var calorie: Int = UserDefaultValue.purposeKcal
        var toastMessage: String = ""
        var calorieUpdated: Bool = false
    }
    
    enum Action {
        case increaseCalorie
        case decreaseCalorie
        case toastMessage(String)
        case removeToastMessage
        case requestUpdate
        case updateSuccess
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .increaseCalorie:
            if state.calorie < 1000 {
                state.calorie += 100
                return .none
            } else {
                return .send(.toastMessage("최대 1000칼로리까지 성장할 수 있어요"))
            }
        case .decreaseCalorie:
            if state.calorie > 100 {
                state.calorie -= 100
                return .none
            } else {
                return .send(.toastMessage("최소 100칼로리 이상 설정해주세요"))
            }
        case .toastMessage(let message):
            if message.isEmpty {
                state.toastMessage = message
                return .none
            } else {
                state.toastMessage = message
                return .run { send in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.removeToastMessage)
                }
            }
        case .removeToastMessage:
            state.toastMessage = ""
            return .none
        case .requestUpdate:
            let calorie = state.calorie
            return .run { send in
                if await update(purposeCalorie: calorie) {
                    return await send(.updateSuccess)
                }
            }
        case .updateSuccess:
            state.calorieUpdated = true
            return .send(.toastMessage("하루 목표 칼로리가 변경되었어요"))
        }
    }
    
    public func update(purposeCalorie: Int) async -> Bool {
        
        let result = await repository.update(name: userNickname,
                                             purposeCalorie: purposeCalorie)
        switch result {
        case .success:
            return true
        case .failure(let failure):
            //TODO: 에러처리
            return false
        }
    }
}
