//
//  TokenInterceptor.swift
//  DDanDDan
//
//  Created by 이지희 on 11/13/24.
//

import Foundation
import Alamofire

public final class TokenInterceptor: RequestInterceptor {
    
    private let maxRetryCount = 3
    private var retryCount = 0
    private let tokenRefreshManager = TokenRefreshManager()

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        var adaptedRequest = urlRequest
        if let url = urlRequest.url?.absoluteString,
           url.contains("/auth/reissue") {
            completion(.success(adaptedRequest))
            return
        }
        
        if let accessToken = UserDefaultValue.accessToken {
            adaptedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(adaptedRequest))
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        print("🔹 Retry 호출된 URL: \(request.request?.url?.absoluteString ?? "unknown")")
        
        guard let response = request.task?.response as? HTTPURLResponse,
                  response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        print("🔹 Response Status Code: \(response.statusCode)")
        
        if retryCount >= maxRetryCount {
            print("🔻 최대 재시도 횟수 초과: 로그아웃 처리")
            retryCount = 0
            Task {
                await UserManager.shared.logout()
            }
            completion(.doNotRetry)
            return
        }
        
        retryCount += 1
        
        
        Task {
            let refreshSuccess = await tokenRefreshManager.refresh()
            
            await MainActor.run {
                if refreshSuccess {
                    self.retryCount = 0
                    completion(.retry)
                } else {
                    self.retryCount = 0
                    completion(.doNotRetry)
                }
            }
        }
    }
}
