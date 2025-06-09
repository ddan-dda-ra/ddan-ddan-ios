//
//  AuthNetwork.swift
//  DDanDDan
//
//  Created by hwikang on 10/23/24.
//

import Foundation
import Alamofire

public struct AuthNetwork {
    private let manager = NetworkManager(withInterceptor: false)
    
    public func login(token: String, tokenType: String, deviceToken: String?) async -> Result<LoginData, NetworkError> {
        var parameter: Parameters = [
            "token": token,
            "tokenType": tokenType
        ]
        if let deviceToken {
            parameter["deviceToken"] = deviceToken
        }
        
        return await manager.request(
                url: PathString.Auth.login,
                method: .post,
                parameters: parameter,
                encoding: JSONEncoding.default,
                excludeAuth: true
            )
    }
    
    public func tokenReissue(refreshToken: String) async -> Result<ReissueData, NetworkError> {
        let parameter: Parameters = [
            "refreshToken": refreshToken
        ]
        
        return await manager.request(
            url: PathString.Auth.reissue,
            method: .post,
            parameters: parameter,
            encoding: JSONEncoding.default,
            excludeAuth: true
        )
    }
}
