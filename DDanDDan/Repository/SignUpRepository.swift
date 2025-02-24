//
//  SignUpRepository.swift
//  DDanDDan
//
//  Created by hwikang on 10/25/24.
//

import Foundation

protocol SignUpRepositoryProtocol {
    func update(name: String?, purposeCalorie: Int?) async -> Result<UserData, NetworkError>
    func getKakaoToken() -> String?
    func login(token: String, tokenType: String) async -> Result<LoginData, NetworkError>
    func addPet(petType: PetType) async -> Result<Pet, NetworkError>
    func setMainPet(petID: String) async -> Result<MainPet, NetworkError>
}

public struct SignUpRepository: SignUpRepositoryProtocol {
    private let network = UserNetwork()
    private let authNetwork = AuthNetwork()
    private let petsNetwork = PetsNetwork()
    
    public func update(name: String?, purposeCalorie: Int?) async -> Result<UserData, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        let result = await network.update(accessToken: accessToken, name: name, purposeCalorie: purposeCalorie)
        if case .success(let userData) = result {
            UserDefaultValue.purposeKcal = userData.purposeCalorie
            UserDefaultValue.nickName = userData.name
        }
        return result
    }
    
    @MainActor
    public func getKakaoToken() -> String? {
        return UserManager.shared.kakaoToken
    }
    
    public func login(token: String, tokenType: String) async -> Result<LoginData, NetworkError> {
        let deviceToken = UserDefaultValue.deviceToken
        return await authNetwork.login(token: token, tokenType: tokenType, deviceToken: deviceToken)
    }
    
    public func addPet(petType: PetType) async -> Result<Pet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await petsNetwork.addPet(accessToken: accessToken, petType: petType)
    }
    
    public func setMainPet(petID: String) async -> Result<MainPet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        return await network.setMainPet(accessToken: accessToken, petID: petID)
    }
}
