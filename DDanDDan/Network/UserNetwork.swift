//
//  UserNetwork.swift
//  DDanDDan
//
//  Created by hwikang on 10/23/24.
//

import Foundation
import Alamofire
public struct UserNetwork {
    private let manager = NetworkManager(interceptor: TokenInterceptor())
    
    // MARK: - GET
    
    public func fetchUserMainPet(accessToken: String) async -> Result<MainPet, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        return await manager.request(
            url: PathString.User.mainPet,
            method: .get,
            headers: headers
        )
    }
    
    public func fetchUserInfo(accessToken: String) async -> Result<UserData, NetworkError> {
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        
        return await manager.request(
            url: PathString.User.user,
            method: .get,
            headers: headers
        )
    }
    
    
    // MARK: - PUT
    
    public func update(
        accessToken: String,
        name: String?,
        purposeCalorie: Int?
    ) async -> Result<UserData, NetworkError> {
        var parameter: Parameters = [:]
        if let name = name {
            parameter["name"] = name
        }
        if let purposeCalorie = purposeCalorie {
            parameter["purposeCalorie"] = purposeCalorie
        }
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        return await manager.request(
            url: PathString.User.user,
            method: .put,
            headers: headers,
            parameters: parameter,
            encoding: JSONEncoding.default
        )
    }
    
    // MARK: - PATCH
    
    public func patchDailyKcal(accessToken: String, calorie: Int) async -> Result<DailyUserData, NetworkError> {
        let parameter: Parameters = ["calorie": calorie]
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        return await manager.request(
            url: PathString.User.updateDailyKcal,
            method: .patch,
            headers: headers,
            parameters: parameter,
            encoding: JSONEncoding.default
            )
    }
    
    public func patchPushNotification(accessToken: String, isOn: Bool) async -> Result<EmptyEntity, NetworkError> {
        let parameter: Parameters = ["isAppPushOn": isOn]
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        return await manager.request(
            url: PathString.User.userSetting,
            method: .patch,
            headers: headers,
            parameters: parameter,
            encoding: JSONEncoding.default
            )
    }
    
    // MARK: - POST
    
    public func setMainPet(accessToken: String, petID: String) async -> Result<MainPet, NetworkError> {
        let parameter: Parameters = ["petId": petID]
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        return await manager.request(
            url: PathString.User.mainPet,
            method: .post,
            headers: headers,
            parameters: parameter,
            encoding: JSONEncoding.default
        )
    }
    
    //MARK: - DELETE
    
    public func deleteUser(accessToken: String, reason: String) async -> Result<EmptyEntity, NetworkError> {
        let parameter: Parameters = ["cause": reason]
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        return await manager.request(url: PathString.User.user,
                                     method: .delete,
                                     headers: headers,
                                     parameters: parameter,
                                     encoding: JSONEncoding.default)
    }
}
