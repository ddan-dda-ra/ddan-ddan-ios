//
//  SettingViewReducer.swift
//  DDanDDan
//
//  Created by keone on 2025/03/07.
//

import Foundation
import ComposableArchitecture

struct SettingViewReducer: Reducer {
    enum Action {
        case toggleNotification(Bool)
        case showLogoutDialog(Bool)
        case toastMessage(String)
        case updateSuccess(notificationState: Bool)
    }
    
    struct State: Equatable {
        var notificationState: Bool = UserDefaultValue.pushNotification
        var showLogoutDialog = false
        var toastMessage: String = ""
    }
    
    private let repository: SettingRepositoryProtocol
    public init(repository: SettingRepositoryProtocol) {
        self.repository = repository
    }
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleNotification:
                let state = state.notificationState
                return .run { send in
                    let result = await repository.patchPushNotification(isOn: !state)
                    switch result {
                    case .success:
                        await send(.updateSuccess(notificationState: !state))
                    case .failure(let failure):
                        await send(.toastMessage("알람 동의 변경 실패 \(failure)"))
                    }
                    
                }
            case let .showLogoutDialog(show):
                state.showLogoutDialog = show
                return .none
            case let .toastMessage(message):
                state.toastMessage = message
            case let.updateSuccess(notificationState):
                UserDefaultValue.pushNotification = notificationState
                state.notificationState = notificationState
            }
            return .none
        }
    }

}
