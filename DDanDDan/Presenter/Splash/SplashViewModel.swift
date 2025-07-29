//
//  SplashViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 11/19/24.
//

import Foundation
final class SplashViewModel: ObservableObject {
    private let coordinator: AppCoordinator
    private let homeRepository: HomeRepository
    
    init(
        coordinator: AppCoordinator,
        homeRepository: HomeRepository
    ) {
        self.coordinator = coordinator
        self.homeRepository = homeRepository
    }
    
    func performInitialSetup() async {
        do {
            let userData = try await unwrapResult(homeRepository.getUserInfo())

            DispatchQueue.main.async {
                self.coordinator.userInfo = userData
                UserDefaultValue.userId = userData.id
                UserDefaultValue.purposeKcal = userData.purposeCalorie
            }

            let petData = try await unwrapResult(homeRepository.getMainPetInfo())

            DispatchQueue.main.async {
                self.coordinator.petInfo = petData
                UserDefaultValue.petType = petData.mainPet.type.rawValue
                UserDefaultValue.petId = petData.mainPet.id
                UserDefaultValue.level = petData.mainPet.level
                
                
                let sharedDefaults = UserDefaults(suiteName: "group.com.DdanDdan")
                sharedDefaults?.set(petData.mainPet.type.rawValue, forKey: "petType")
                sharedDefaults?.set(petData.mainPet.level, forKey: "petLevel")
                sharedDefaults?.synchronize()

                let info: [String: Any] = [
                    "purposeKcal": userData.purposeCalorie,
                    "petType": petData.mainPet.type.rawValue,
                    "level": petData.mainPet.level
                ]
                WatchConnectivityManager.shared.transferUserInfo(info: info)
                self.coordinator.setRoot(to: .mainTab)
            }
        } catch {
            DispatchQueue.main.async {
                self.coordinator.setRoot(to: .login)
            }
        }
    }
    
    @MainActor
    func checkForceUpdate() -> Bool {
        guard let forceUpdateConfig = RemoteConfigManager.shared.getJsonValue(key: .forceUpdate),
              let minAppVersionIOS = forceUpdateConfig["min_app_version_ios"] as? String,
              let forceUpdateEnabled = forceUpdateConfig["force_update_enabled"] as? Bool else {
                  return false
              }
        
        return forceUpdateEnabled && isVersionLower(minimum: minAppVersionIOS)
    }
    
    private func isVersionLower(minimum: String) -> Bool {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        return current.compare(minimum, options: .numeric) == .orderedAscending
    }
    
    func getAppStoreURL() -> URL? {
        return URL(string: "https://apps.apple.com/app/id6736588896")
    }
    
    @MainActor
    func navigateToNextScreen() {
        if !UserDefaultValue.isOnboardingComplete {
            coordinator.setRoot(to: .onboarding)
        } else if let accessToken = UserManager.shared.accessToken,
                  !accessToken.isEmpty {
            if UserManager.shared.isSignUpRequired() {
                coordinator.setRoot(to: .signUp)
            } else {
                Task {
                    await self.performInitialSetup()
                }
            }
        } else {
            coordinator.setRoot(to: .login)
        }
    }
    
    /// 통신 결과를 안전하게 처리하는 헬퍼 메서드
    private func unwrapResult<T>(_ result: Result<T, NetworkError>) async throws -> T {
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
