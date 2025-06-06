//
//  UserManager.swift
//  DDanDDan
//
//  Created by hwikang on 10/14/24.
//

import Foundation

actor UserManager: ObservableObject {
    static let shared = UserManager()
    
    @MainActor @Published var accessToken: String? = UserDefaultValue.acessToken
    @MainActor public var kakaoToken: String?
    @MainActor public var appleToken: String?
    @MainActor public var coordinator: AppCoordinator?
    
    private var refreshToken: String? = UserDefaultValue.refreshToken
    private var deviceToken: String? = UserDefaultValue.refreshToken
    @MainActor private var isOnboardingComplete: Bool = UserDefaultValue.isOnboardingComplete
    
    private init() {
        
    }
    
    func setToken(accessToken: String, refreshToken: String) async {
        self.refreshToken = refreshToken
        await MainActor.run {
            self.accessToken = accessToken
            
        }
    }
    
    @MainActor
    func isSignUpRequired() -> Bool {
        !isOnboardingComplete
    }
    
    func login(loginData: LoginData) async {
        refreshToken = loginData.refreshToken
        UserDefaultValue.acessToken = loginData.accessToken
        UserDefaultValue.refreshToken = loginData.refreshToken
        UserDefaultValue.isOnboardingComplete = loginData.isOnboardingComplete
        AnalyticsManager.shared.setUserProperty(property: .userID(loginData.user.id))
        AnalyticsManager.shared.setUserProperty(property: .userName(loginData.user.name))
        await MainActor.run {
            isOnboardingComplete = loginData.isOnboardingComplete
            accessToken = loginData.accessToken
        }
    }
    
    func logout() async {
        refreshToken = nil
        await MainActor.run {
            accessToken = nil
            UserDefaultValue.acessToken = nil
            coordinator?.setRoot(to: .login)
        }
    }
}
