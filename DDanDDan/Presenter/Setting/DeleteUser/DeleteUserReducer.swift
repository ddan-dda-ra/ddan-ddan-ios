//
//  DeleteUserReducer.swift
//  DDanDDan
//
//  Created by hwikang on 10/7/24.
//

import Foundation
import ComposableArchitecture

struct DeleteUserReducer: Reducer {
    private let repository: SettingRepositoryProtocol
    public init(repository: SettingRepositoryProtocol) {
        self.repository = repository
    }
    enum Action {
        case selectReason(String)
        case checkButton
        case deleteUser
        case deleteFinished
    }

    struct State: Equatable {
        var reasons: [String] = [
            "쓰지 않는 앱이에요", "오류가 생겨서 쓸 수 없어요", "개인정보가 불안해요", "앱 사용법을 모르겠어요", "기타"
        ]
        var name: String = UserDefaultValue.nickName
        var selectedReason: Set<String> = []
        var isButtonChecked: Bool = false
        var deleteFinished: Bool = false
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .selectReason(let reason):
            if state.selectedReason.contains(reason) {
                state.selectedReason.remove(reason)
            } else {
                state.selectedReason.insert(reason)
            }
        case .checkButton:
            state.isButtonChecked = !state.isButtonChecked
        case .deleteUser:
            let reasons = state.selectedReason
            return .run { send in
                _ = await deleteUser(reasons: reasons)
                return await send(.deleteFinished)
            
            }
        case .deleteFinished:
            state.deleteFinished = true
        }
        
        return .none
    }
    private func deleteUser(reasons: Set<String>) async -> Bool {
        let result = await repository.deleteUser(reason: reasons.reduce("") {
            $0.isEmpty ? $1 : $0 + ", " + $1 }
        )
        switch result {
        case .success:
            return true
        case .failure(let error):
            //TODO: 에러처리
            return false
        }
        
    }
}
