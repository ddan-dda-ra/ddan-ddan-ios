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
    func updateNickname(name: String) async -> Bool
    func updateCalorie(calorie: Int) async -> Bool
    func login() async -> Bool
    func updatePet(petType: PetType) async -> Bool
}
@MainActor
final class SignUpViewModel: SignUpViewModelProtocol {
    private let repository: SignUpRepositoryProtocol
    private let catalogRepository: any PetCatalogRepositoryProtocol
    @Published private(set) var bootstrapState: AuthenticatedBootstrapState = .idle
    @Published private(set) var preparedMainPet: MainPet?

    init(
        repository: SignUpRepositoryProtocol,
        catalogRepository: any PetCatalogRepositoryProtocol = PetCatalogRepository.shared
    ) {
        self.repository = repository
        self.catalogRepository = catalogRepository
    }
    public func updatePet(petType: PetType) async -> Bool {
        let result = await repository.addPet(petType: petType.rawValue)
        switch result {
        case .success(let pet):
            UserDefaultValue.petType = pet.type
            UserDefaultValue.petId = pet.id
            return await setMainPet(petID: pet.id)
        case .failure(let failure):
            // TODO: 에러 처리
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
            return true
        case .failure(let failure):
            // TODO: 에러 처리
            return false
        }
    }
    
    public func updateNickname(name: String) async -> Bool {
        let result = await repository.update(name: name, purposeCalorie: 100)
        switch result {
        case .success:
            return true
        case .failure(let failure):
            // TODO: 에러 처리
            return false
        }
    }
    public func updateCalorie(calorie: Int) async -> Bool {
        let name = UserDefaultValue.nickName
        let result = await repository.update(name: name, purposeCalorie: calorie)
        UserDefaultValue.purposeKcal = calorie
        switch result {
        case .success:
            return true
        case .failure(let failure):
            // TODO: 에러 처리
            return false
        }
    }
    
    public func login() async -> Bool {
        guard bootstrapState != .loading else { return false }
        bootstrapState = .loading
        guard let kakaoToken = repository.getKakaoToken() else {
            bootstrapState = .failed("로그인 정보를 확인하지 못했어요. 다시 시도해 주세요.")
            return false
        }
        let result = await repository.login(token: kakaoToken, tokenType: "KAKAO")
        switch result {
        case .success(let loginData):
            await UserManager.shared.login(loginData: loginData)
            guard let mainPet = preparedMainPet else {
                bootstrapState = .failed("메인 펫 정보를 확인하지 못했어요. 다시 시도해 주세요.")
                return false
            }
            let bootstrap = await catalogRepository.prepareForMain(
                petType: mainPet.mainPet.type,
                level: mainPet.mainPet.level
            )
            guard case let .success(snapshot) = bootstrap, !snapshot.pets.isEmpty else {
                bootstrapState = .failed("펫 데이터를 준비하지 못했어요. 다시 시도해 주세요.")
                return false
            }
            bootstrapState = .idle
            return true
        case .failure(let failure):
            bootstrapState = .failed("로그인에 실패했어요. 다시 시도해 주세요.")
            return false
        }
    }
}
