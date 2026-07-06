//
//  SplashViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 11/19/24.
//

import Foundation
import OSLog

public enum AuthenticatedBootstrapState: Equatable {
    case idle
    case loading
    case failed(String)
}

@MainActor
final class SplashViewModel: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DDanDDan", category: "Splash")
    private let coordinator: AppCoordinator
    private let homeRepository: HomeRepositoryProtocol
    private let catalogRepository: any PetCatalogRepositoryProtocol
    
    @Published var updateAlertMessage: String = ""
    @Published private(set) var bootstrapState: AuthenticatedBootstrapState = .idle
    
    init(
        coordinator: AppCoordinator,
        homeRepository: HomeRepositoryProtocol,
        catalogRepository: any PetCatalogRepositoryProtocol = PetCatalogRepository.shared
    ) {
        self.coordinator = coordinator
        self.homeRepository = homeRepository
        self.catalogRepository = catalogRepository
    }
    
    func performInitialSetup() async {
        guard bootstrapState != .loading else { return }
        bootstrapState = .loading
        do {
            let userData = try await unwrapResult(homeRepository.getUserInfo())
            let petData = try await unwrapResult(homeRepository.getMainPetInfo())
            let catalogBootstrap = await catalogRepository.prepareForMain(
                petType: petData.mainPet.type,
                level: petData.mainPet.level
            )
            guard case let .success(snapshot) = catalogBootstrap else {
                Self.logger.error("Pet catalog bootstrap failed: \(String(describing: catalogBootstrap), privacy: .public)")
                bootstrapState = .failed("펫 데이터를 준비하지 못했어요. 다시 시도해 주세요.")
                return
            }

            UserDefaultValue.userId = userData.id
            UserDefaultValue.purposeKcal = userData.purposeCalorie
            UserDefaultValue.petType = petData.mainPet.type
            UserDefaultValue.petId = petData.mainPet.id
            UserDefaultValue.level = petData.mainPet.level

            let sharedDefaults = UserDefaults(suiteName: "group.com.DdanDdan")
            sharedDefaults?.set(petData.mainPet.type, forKey: "petType")
            sharedDefaults?.set(petData.mainPet.level, forKey: "petLevel")
            sharedDefaults?.synchronize()

            let presentation = PetPresentation.resolve(
                petType: petData.mainPet.type,
                petLevel: petData.mainPet.level,
                snapshot: snapshot
            )
            await WatchConnectivityManager.shared.syncPet(
                purposeKcal: userData.purposeCalorie,
                petType: petData.mainPet.type,
                level: petData.mainPet.level,
                presentation: presentation
            )
            coordinator.commitAuthenticatedBootstrap(userInfo: userData, petInfo: petData)
            bootstrapState = .idle
        } catch {
            Self.logger.error("Initial setup failed: \(error.localizedDescription, privacy: .public)")
            bootstrapState = .failed("정보를 불러오지 못했어요. 다시 시도해 주세요.")
        }
    }

    func retryInitialSetup() async {
        guard bootstrapState != .loading else { return }
        await performInitialSetup()
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
