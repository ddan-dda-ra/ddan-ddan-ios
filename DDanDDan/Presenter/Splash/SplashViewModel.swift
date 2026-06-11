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
    
    @Published var updateAlertMessage: String = ""
    
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
    func checkForceUpdate() async -> Bool {
        let defaultMessage = "새로운 버전이 출시되었습니다. 원활한 사용을 위해 업데이트해 주세요."
        do {
            let path = "app_version/iOS"
            guard let data = try await RealtimeDBManager.shared.getDictionaryValue(path: path),
                  let minVersion = data["minimum_version"] as? String,
                  !minVersion.isEmpty else {
                UserDefaultValue.cachedMinimumVersion = nil
                UserDefaultValue.cachedUpdateMessage = defaultMessage
                self.updateAlertMessage = defaultMessage
                return false
            }

            UserDefaultValue.cachedMinimumVersion = minVersion
            UserDefaultValue.cachedUpdateMessage = (data["update_message"] as? String) ?? defaultMessage

            self.updateAlertMessage = UserDefaultValue.cachedUpdateMessage
            return isVersionLower(minimum: minVersion)
        } catch {
            print("Force update check failed: \(error)")
            return checkCachedMinimumVersion()
        }
    }

    private func checkCachedMinimumVersion() -> Bool {
        guard let cached = UserDefaultValue.cachedMinimumVersion else {
            return false
        }
        self.updateAlertMessage = UserDefaultValue.cachedUpdateMessage
        return isVersionLower(minimum: cached)
    }
    
    private func isVersionLower(minimum: String) -> Bool {
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return false
        }
        
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
