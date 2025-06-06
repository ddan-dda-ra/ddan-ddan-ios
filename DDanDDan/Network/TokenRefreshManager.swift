//
//  TokenRefreshManager.swift
//  DDanDDan
//
//  Created by 이지희 on 6/6/25.
//

import Foundation

actor TokenRefreshManager {
    private var isRefreshing = false
    private var refreshTask: Task<Bool, Never>?
    
    func refresh() async -> Bool {
        if let existingTask = refreshTask {
            return await existingTask.value
        }
        
        let task = Task<Bool, Never> {
            isRefreshing = true
            
            let network = AuthNetwork()
            let refreshToken = UserDefaultValue.refreshToken ?? ""
            let result = await network.tokenReissue(refreshToken: refreshToken)
            
            switch result {
            case .success(let reissueData):
                print("🔹 토큰 재발급 완료")
                UserDefaultValue.accessToken = reissueData.accessToken
                UserDefaultValue.refreshToken = reissueData.refreshToken
                return true
                
            case .failure(let failure):
                print("🔻 토큰 재발급 실패: \(failure.localizedDescription)")
                await UserManager.shared.logout()
                return false
            }
        }
        
        refreshTask = task
        let result = await task.value
        
        // Task 완료 후 정리
        isRefreshing = false
        refreshTask = nil
        
        return result
    }
    
    var isCurrentlyRefreshing: Bool {
        isRefreshing
    }
}
