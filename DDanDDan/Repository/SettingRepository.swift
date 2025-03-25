//
//  SettingRepository.swift
//  DDanDDan
//
//  Created by hwikang on 10/28/24.
//

import Foundation

protocol SettingRepositoryProtocol {
    func update(name: String?, purposeCalorie: Int?) async -> Result<UserData, NetworkError>
    func deleteUser(reason: String) async -> Result<EmptyEntity, NetworkError>
    func patchPushNotification(isOn: Bool) async -> Result<EmptyEntity, NetworkError>
}

public struct SettingRepository: SettingRepositoryProtocol {
    private let network = UserNetwork()
    
    public func update(name: String?, purposeCalorie: Int?) async -> Result<UserData, NetworkError> { 
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        let result = await network.update(accessToken: accessToken, name: name, purposeCalorie: purposeCalorie)
        if case .success(let userData) = result {
            UserDefaultValue.purposeKcal = userData.purposeCalorie
            UserDefaultValue.nickName = userData.name
        }
        return result
    }
    public func deleteUser(reason: String) async -> Result<EmptyEntity, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await network.deleteUser(accessToken: accessToken, reason: reason)
    }
    
    public func patchPushNotification(isOn: Bool) async -> Result<EmptyEntity, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await network.patchPushNotification(accessToken: accessToken, isOn: isOn)
    }
}
