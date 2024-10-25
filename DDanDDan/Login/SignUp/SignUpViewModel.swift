//
//  SignUpCalorieViewModel.swift
//  DDanDDan
//
//  Created by hwikang on 8/24/24.
//

import Foundation
public protocol SignUpViewModelProtocol {
    func updateNickname(name: String) async -> Bool
    func updateCalorie(calorie: Int) async -> Bool
    func login() async -> Bool
}
struct SignUpViewModel: SignUpViewModelProtocol {
    private let repository: SignUpRepositoryProtocol
    init(repository: SignUpRepositoryProtocol) {
        self.repository = repository
    }
    public func updateEgg() {
        
    }
    
    public func updateNickname(name: String) async -> Bool {
        let result = await repository.update(name: name, purposeCalorie: nil)
        switch result {
        case .success:
            return true
        case .failure(let failure):
            // TODO: 에러 처리
            return false
        }
    }
    public func updateCalorie(calorie: Int) async -> Bool {
        let result = await repository.update(name: nil, purposeCalorie: calorie)
        switch result {
        case .success:
            return true
        case .failure(let failure):
            // TODO: 에러 처리
            return false
        }
    }
    
    public func login() async -> Bool {
        guard let kakaoToken = repository.getKakaoToken() else { return false}
        let result = await repository.login(token: kakaoToken, tokenType: "KAKAO")
        switch result {
        case .success(let loginData):
            await UserManager.shared.login(loginData: loginData)
            return true
        case .failure(let failure):
            // TODO: 에러 처리
            return false
        }
    }
}