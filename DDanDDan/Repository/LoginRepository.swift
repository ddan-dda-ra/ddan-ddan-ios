//
//  SignUpRepository.swift
//  DDanDDan
//
//  Created by hwikang on 10/23/24.
//

import Foundation

protocol LoginRepositoryProtocol {
    func login(token: String, tokenType: String) async -> Result<LoginData, NetworkError>
}

public struct LoginRepository: LoginRepositoryProtocol {
    private let network = AuthNetwork()
    
    public func login(token: String, tokenType: String) async -> Result<LoginData, NetworkError> {
        let deviceToken = UserDefaultValue.deviceToken
        return await network.login(token: token, tokenType: tokenType, deviceToken: deviceToken)
    }
}
