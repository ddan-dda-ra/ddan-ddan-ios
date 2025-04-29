//
//  HomeRepository.swift
//  DDanDDan
//
//  Created by 이지희 on 11/7/24.
//

import Foundation

public protocol HomeRepositoryProtocol {
    // MARK: GET Method
    func getUserInfo() async -> Result<HomeUserInfo, NetworkError>
    func getMainPetInfo() async -> Result<MainPet, NetworkError>
    func getPetArchive() async -> Result<PetArchiveModel, NetworkError>
    func getSpecificPet(petId: String) async -> Result<Pet, NetworkError>
    
    // MARK: POST Method
    func updateMainPet(petId: String) async -> Result<MainPet, NetworkError>
    func feedPet(petId: String) async -> Result<UserPetData, NetworkError>
    func playPet(petId: String) async -> Result<UserPetData, NetworkError>
    func addNewPet(petType: PetType) async -> Result<Pet, NetworkError>
    func addNewRandomPet() async -> Result<Pet, NetworkError>
    
    // MARK: PATCH Method
    func updateDailyKcal(calorie: Int) async -> Result<DailyUserData, NetworkError>
}


public struct HomeRepository: HomeRepositoryProtocol {
    
    private let userNetwork = UserNetwork()
    private let petNetwork = PetsNetwork()
    private let authNetwork = AuthNetwork()
    
    // MARK: - GET
    public func getUserInfo() async -> Result<HomeUserInfo, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
       // print(accessToken)
        let result = await userNetwork.fetchUserInfo(accessToken: accessToken)

        
        return result.map { userData in
            AnalyticsManager.shared.setUserProperty(property: .userID(userData.id))
            AnalyticsManager.shared.setUserProperty(property: .userName(userData.name))
            UserDefaultValue.nickName = userData.name
            return HomeUserInfo(
                id: userData.id,
                purposeCalorie: userData.purposeCalorie,
                foodQuantity: userData.foodQuantity,
                toyQuantity: userData.toyQuantity
            )
        }
    }
    
    public func getMainPetInfo() async -> Result<MainPet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await userNetwork.fetchUserMainPet(accessToken: accessToken)
        return result
    }
    
    public func getPetArchive() async -> Result<PetArchiveModel, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await petNetwork.fetchPetArchieve(accessToken: accessToken)
        return result
    }
    
    public func getSpecificPet(petId: String) async -> Result<Pet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await petNetwork.fetchSpecificPet(accessToken: accessToken, petId: petId)
        return result
    }
    
    // MARK: - POST
    
    public func updateMainPet(petId: String) async -> Result<MainPet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await userNetwork.setMainPet(accessToken: accessToken, petID: petId)
        return result
    }
    
    public func feedPet(petId: String) async -> Result<UserPetData, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await petNetwork.postPetFeed(accessToken: accessToken, petId: petId)
        
        // AC003 토큰 만료시 토큰 재발행후 재시도
        if case .failure(let error) = result, case let .serverError(_, serverCode) = error,
           serverCode == "AC003", await refreshToken() {
            return await feedPet(petId: petId)
        }
        
        return result
    }
    
    public func playPet(petId: String) async -> Result<UserPetData, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await petNetwork.postPetPlay(accessToken: accessToken, petId: petId)
        return result
    }
    
    public func addNewPet(petType: PetType) async -> Result<Pet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await petNetwork.addPet(accessToken: accessToken, petType: petType)
        return result
    }
    
    public func addNewRandomPet() async -> Result<Pet, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await petNetwork.addRandomPet(accessToken: accessToken)
        return result
    }
    
    public func updateDailyKcal(calorie: Int) async -> Result<DailyUserData, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
        let result = await userNetwork.patchDailyKcal(accessToken: accessToken, calorie: calorie)
        return result
    }
    
    private func refreshToken() async -> Bool {
        guard let refreshToken = UserDefaultValue.refreshToken else { return false }
        let result = await authNetwork.tokenReissue(refreshToken: refreshToken)
        switch result {
        case .success(let reissueData):
            UserDefaultValue.acessToken = reissueData.accessToken
            UserDefaultValue.refreshToken = reissueData.refreshToken
            return true
        case .failure:
            return false
        }
    }
}
