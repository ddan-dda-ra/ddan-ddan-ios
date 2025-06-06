//
//  PetsNetwork.swift
//  DDanDDan
//
//  Created by hwikang on 10/28/24.
//


import Foundation
import Alamofire

public struct PetsNetwork {
    private let manager = NetworkManager()
    
    // MARK: - GET
    
    public func fetchSpecificPet(accessToken: String, petId: String) async -> Result<Pet, NetworkError> {
        return await manager.request(
            url: PathString.Pet.fetchPet + petId,
            method: .get
        )
    }
    
    public func fetchPetArchieve(accessToken: String) async -> Result<PetArchiveModel, NetworkError> {
        return await manager.request(
            url: PathString.Pet.userPets,
            method: .get
        )
    }
    
    // MARK: - POST
    
    public func addPet(accessToken: String, petType: PetType) async -> Result<Pet, NetworkError> {
        let parameter: Parameters = [
            "petType": petType.rawValue
        ]
        
        return await manager.request(
            url: PathString.Pet.userPets,
            method: .post,
            parameters: parameter,
            encoding: JSONEncoding.default
        )
    }
    
    public func addRandomPet(accessToken: String) async -> Result<Pet, NetworkError> {
        return await manager.request(
            url: PathString.Pet.randomPet,
            method: .post
        )
    }
    
    public func postPetFeed(accessToken: String, petId: String) async -> Result<UserPetData, NetworkError> {
        return await manager.request(
            url: PathString.Pet.fetchPet + petId + "/food",
            method: .post,
            encoding: JSONEncoding.default
        )
    }
    
    public func postPetPlay(accessToken: String, petId: String) async -> Result<UserPetData, NetworkError> {
        return await manager.request(
            url: PathString.Pet.fetchPet + petId + "/play",
            method: .post,
            encoding: JSONEncoding.default
        )
    }
}

