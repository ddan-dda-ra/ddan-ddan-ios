//
//  TokenInterceptor.swift
//  DDanDDan
//
//  Created by 이지희 on 11/13/24.
//

import Foundation

import Alamofire

public final class TokenInterceptor: Interceptor {
    
    private let maxRetryCount = 3
    private var retryCounts: [URLRequest: Int] = [:]
    
    public override func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
        
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        var currentRetryCount = retryCounts[request.request ?? URLRequest(url: URL(string: "about:blank")!)] ?? 0
        
        if currentRetryCount >= maxRetryCount {
            print("🔻 최대 재시도 횟수 초과: 로그아웃 처리")
            Task {
                await UserManager.shared.logout()
            }
            completion(.doNotRetry)
            return
        }
        
        let network = AuthNetwork()
        let refreshToken = UserDefaultValue.refreshToken
        
        Task {
            let result = await network.tokenReissue(refreshToken: refreshToken ?? "")
            if case .success(let reissueData) = result {
                print("🔹 토큰 재발급 완료 API 재시도")
                UserDefaultValue.acessToken = reissueData.accessToken
                UserDefaultValue.refreshToken = reissueData.refreshToken
                
                retryCounts[request.request ?? URLRequest(url: URL(string: "about:blank")!)] = currentRetryCount + 1
                completion(.retry)
            } else if case .failure(let failure) = result {
                print("🔻 Retry Error 발생")
                print("Error: \(failure.localizedDescription)")
                
                Task {
                    await UserManager.shared.logout()
                }
                
                completion(.doNotRetry)
            }
        }
    }
}
