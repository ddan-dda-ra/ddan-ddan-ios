//
//  NewPetViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 11/20/24.
//

import Foundation


final class NewPetViewModel: ObservableObject {
    private let homeRepository: HomeRepository
    private let coordinator: AppCoordinator
    
    init(
        homeRepository: HomeRepository,
        coordinator: AppCoordinator
    ) {
        self.homeRepository = homeRepository
        self.coordinator = coordinator
    }
    
    func createRandomPet() async {
        let randomPetResult = await homeRepository.addNewRandomPet()
        switch randomPetResult {
        case .success(let pet):
            let mainPetResult = await homeRepository.updateMainPet(petId: pet.id)
            switch mainPetResult {
            case .success(_):
                await coordinator.triggerHomeUpdate()
                await coordinator.pop()
            case .failure(let error):
                print("메인 펫 설정에 실패했습니다 \(error.localizedDescription)")
            }
        case .failure(let error):
            print("랜덤 펫 생성에 실패했습니다 \(error.localizedDescription)")
        }
    }
}
