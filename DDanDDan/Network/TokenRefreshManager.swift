//
//  TokenRefreshManager.swift
//  DDanDDan
//
//  Created by 이지희 on 6/6/25.
//

import Foundation

actor TokenRefreshManager {
    static let shared = TokenRefreshManager()
    private let reissue: @Sendable (String) async -> Result<ReissueData, NetworkError>
    private let applyReissue: @Sendable (ReissueData) async -> Void
    private let logout: @Sendable () async -> Void

    init(
        reissue: @escaping @Sendable (String) async -> Result<ReissueData, NetworkError> = { refreshToken in
            await AuthNetwork().tokenReissue(refreshToken: refreshToken)
        },
        applyReissue: @escaping @Sendable (ReissueData) async -> Void = { reissueData in
            UserDefaultValue.accessToken = reissueData.accessToken
            UserDefaultValue.refreshToken = reissueData.refreshToken
            await UserManager.shared.setToken(
                accessToken: reissueData.accessToken,
                refreshToken: reissueData.refreshToken
            )
        },
        logout: @escaping @Sendable () async -> Void = {
            await UserManager.shared.logout()
        }
    ) {
        self.reissue = reissue
        self.applyReissue = applyReissue
        self.logout = logout
    }

    private var refreshTask: Task<Bool, Never>?
    private var failedAuthorization: String?
    private var failedRefreshToken: String?
    
    func refresh(failedRequestAuthorization: String?) async -> Bool {
        let currentAuthorization = UserDefaultValue.accessToken.map { "Bearer \($0)" }

        // 이미 다른 요청이 토큰을 갱신했다면 실패했던 요청만 새 토큰으로 재시도한다.
        if let failedRequestAuthorization,
           let currentAuthorization,
           failedRequestAuthorization != currentAuthorization {
            return true
        }

        // 같은 만료 토큰의 재발급이 실패했다면 뒤늦게 도착한 401도 실패 결과를 공유한다.
        if let failedAuthorization,
           failedAuthorization == failedRequestAuthorization,
           failedRefreshToken == UserDefaultValue.refreshToken {
            return false
        }

        if let existingTask = refreshTask {
            return await existingTask.value
        }
        
        guard let refreshToken = UserDefaultValue.refreshToken, !refreshToken.isEmpty else {
            failedAuthorization = failedRequestAuthorization
            failedRefreshToken = nil
            return false
        }

        let reissue = self.reissue
        let applyReissue = self.applyReissue
        let logout = self.logout
        let task = Task<Bool, Never> {
            let result = await reissue(refreshToken)
            
            switch result {
            case .success(let reissueData):
                print("🔹 토큰 재발급 완료")
                await applyReissue(reissueData)
                return true
                
            case .failure(let failure):
                print("🔻 토큰 재발급 실패: \(failure.localizedDescription)")
                await logout()
                return false
            }
        }
        
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        failedAuthorization = result ? nil : failedRequestAuthorization
        failedRefreshToken = result ? nil : refreshToken
        return result
    }
}
