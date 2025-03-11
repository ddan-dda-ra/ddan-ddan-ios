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
    }
    
    struct State: Equatable {
        var notificationState: Bool = UserDefaultValue.pushNotification
        var showLogoutDialog = false
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleNotification:
                //TODO: API 연동
                state.notificationState = !state.notificationState
                return .none
            case let .showLogoutDialog(show):
                state.showLogoutDialog = show
                return .none
            }
        }
    }
}
