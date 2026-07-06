//
//  SignUpCalorieViewModel.swift
//  DDanDDan
//
//  Created by hwikang on 8/24/24.
//

import Foundation

@MainActor
public protocol SignUpViewModelProtocol: ObservableObject {
    var bootstrapState: AuthenticatedBootstrapState { get }
    var preparedMainPet: MainPet? { get }
    var preparedUserInfo: HomeUserInfo? { get }
    func updateNickname(name: String) async -> Bool
    func updateCalorie(calorie: Int) async -> Bool
    func login() async -> Bool
    func updatePet(petType: PetType) async -> Bool
}
@MainActor
final class SignUpViewModel: SignUpViewModelProtocol {
    private let repository: SignUpRepositoryProtocol
    private let catalogRepository: any PetCatalogRepositoryProtocol
    private let homeRepository: HomeRepositoryProtocol
    private let watchSyncer: any WatchPetSyncing
    @Published private(set) var bootstrapState: AuthenticatedBootstrapState = .idle
    @Published private(set) var preparedMainPet: MainPet?
    @Published private(set) var preparedUserInfo: HomeUserInfo?

    init(
        repository: SignUpRepositoryProtocol,
        catalogRepository: any PetCatalogRepositoryProtocol = PetCatalogRepository.shared,
        homeRepository: HomeRepositoryProtocol = HomeRepository(),
        watchSyncer: any WatchPetSyncing = WatchConnectivityManager.shared
    ) {
        self.repository = repository
        self.catalogRepository = catalogRepository
        self.homeRepository = homeRepository
        self.watchSyncer = watchSyncer
    }
    public func updatePet(petType: PetType) async -> Bool {
        bootstrapState = .loading
        let result = await repository.addPet(petType: petType.rawValue)
        switch result {
        case .success(let pet):
            UserDefaultValue.petType = pet.type
            UserDefaultValue.petId = pet.id
            return await setMainPet(petID: pet.id)
        case .failure:
            bootstrapState = .failed("펫을 추가하지 못했어요. 다시 시도해 주세요.")
            return false
        }
    }
    
    private func setMainPet(petID: String) async -> Bool {
        let result = await repository.setMainPet(petID: petID)
        switch result {
        case let .success(mainPet):
            preparedMainPet = mainPet
            UserDefaultValue.petType = mainPet.mainPet.type
            UserDefaultValue.petId = mainPet.mainPet.id
            UserDefaultValue.level = mainPet.mainPet.level
            bootstrapState = .idle
            return true
        case .failure:
            bootstrapState = .failed("메인 펫을 설정하지 못했어요. 다시 시도해 주세요.")
            return false
        }
    }
    
    public func updateNickname(name: String) async -> Bool {
        bootstrapState = .loading
        let result = await repository.update(name: name, purposeCalorie: 100)
        switch result {
        case .success:
            bootstrapState = .idle
            return true
        case .failure:
            bootstrapState = .failed("별명을 저장하지 못했어요. 다시 시도해 주세요.")
            return false
        }
    }
    public func updateCalorie(calorie: Int) async -> Bool {
        bootstrapState = .loading
        let name = UserDefaultValue.nickName
        let result = await repository.update(name: name, purposeCalorie: calorie)
        switch result {
        case .success:
            bootstrapState = .idle
            return true
        case .failure:
            bootstrapState = .failed("목표 칼로리를 저장하지 못했어요. 다시 시도해 주세요.")
            return false
        }
    }
    
    public func login() async -> Bool {
        guard bootstrapState != .loading else { return false }
        bootstrapState = .loading
        guard let credential = repository.getLoginCredential() else {
            bootstrapState = .failed("로그인 정보를 확인하지 못했어요. 다시 시도해 주세요.")
            return false
        }
        let result = await repository.login(token: credential.token, tokenType: credential.tokenType)
        switch result {
        case .success(let loginData):
            await UserManager.shared.login(loginData: loginData)
            async let userInfoResult = homeRepository.getUserInfo()
            async let mainPetResult = homeRepository.getMainPetInfo()
            guard case let .success(userInfo) = await userInfoResult,
                  case let .success(mainPet) = await mainPetResult else {
                bootstrapState = .failed("메인 펫 정보를 확인하지 못했어요. 다시 시도해 주세요.")
                return false
            }
            let bootstrap = await catalogRepository.prepareForMain(
                petType: mainPet.mainPet.type,
                level: mainPet.mainPet.level
            )
            guard case let .success(snapshot) = bootstrap else {
                bootstrapState = .failed("펫 데이터를 준비하지 못했어요. 다시 시도해 주세요.")
                return false
            }
            let presentation = PetPresentation.resolve(
                petType: mainPet.mainPet.type,
                petLevel: mainPet.mainPet.level,
                snapshot: snapshot
            )
            guard presentation.level?.assetURLs.count == 3 else {
                bootstrapState = .failed("선택한 펫 데이터를 찾을 수 없어요. 다시 시도해 주세요.")
                return false
            }
            await watchSyncer.syncPet(
                purposeKcal: userInfo.purposeCalorie,
                petType: mainPet.mainPet.type,
                level: mainPet.mainPet.level,
                presentation: presentation
            )
            preparedUserInfo = userInfo
            preparedMainPet = mainPet
            UserDefaultValue.userId = userInfo.id
            UserDefaultValue.purposeKcal = userInfo.purposeCalorie
            bootstrapState = .idle
            return true
        case .failure:
            bootstrapState = .failed("로그인에 실패했어요. 다시 시도해 주세요.")
            return false
        }
    }
}
