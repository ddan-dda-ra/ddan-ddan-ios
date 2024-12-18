//
//  UpdateNicknameReducer.swift
//  DDanDDan
//
//  Created by hwikang on 9/26/24.
//

import Foundation
import ComposableArchitecture

struct UpdateNicknameReducer: Reducer {
    private let repository: SettingRepositoryProtocol
    private let purposeCalorie = UserDefaultValue.purposeKcal
    
    public init(repository: SettingRepositoryProtocol) {
        self.repository = repository
    }
    
    struct State: Equatable {
        @BindingState var nickName = UserDefaultValue.nickName
        var buttonDisabled: Bool = true
        var calorieUpdated: Bool = false
        var toastMessage: String = ""
    }
    enum Action {
        case inputNickname(String)
        case requestUpdate
        case toastMessage(String)
        case updateSuccess
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .inputNickname(let nickname):
                state.nickName = nickname
                state.buttonDisabled = state.nickName.isEmpty
            case .requestUpdate:
                let nickname = state.nickName
                return .run { send in
                    if try await update(nickname: nickname) {
                        return await send(.updateSuccess)
                    }
                }  catch: { error, send in
                    await send(.toastMessage("별명 변경 실패 \(error)"))
                }
            case .toastMessage(let message):
                state.toastMessage = message
            case .updateSuccess:
                state.calorieUpdated = true
            }
            return .none
        }
    }
    public func update(nickname: String) async throws -> Bool {

         let result = await repository.update(name: nickname, purposeCalorie: purposeCalorie)
         switch result {
         case .success:
             return true
         case .failure(let failure):
             throw failure
         }
     }
}
