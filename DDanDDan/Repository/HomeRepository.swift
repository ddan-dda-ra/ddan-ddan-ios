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
    
    // MARK: - GET
    public func getUserInfo() async -> Result<HomeUserInfo, NetworkError> {
        guard let accessToken = await UserManager.shared.accessToken else { return .failure(.requestFailed("Access Token Nil"))}
        
       // print(accessToken)
        let result = await userNetwork.fetchUserInfo(accessToken: accessToken)
        
        return result.map { userData in
            HomeUserInfo(
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
}
