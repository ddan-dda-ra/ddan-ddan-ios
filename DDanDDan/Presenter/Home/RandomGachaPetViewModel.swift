//
//  RandomGachaPetViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/4/25.
//

import SwiftUI
import Combine


final class RandomGachaPetViewModel: ObservableObject {
    
    private let homeRepository: HomeRepositoryProtocol
    let dismissPublisher = PassthroughSubject<Void, Never>()
    
    @Published var gachaResult: Pet?
    @Published var isSelectedRandomPet: Bool = false
    
    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }
    
    func tapSelectButton() {
        Task {
            await selectRandomPet()
            await MainActor.run {
                isSelectedRandomPet = true
            }
        }
    }

    
    func tapGrowupButton() {
        guard let gachaResultId = gachaResult?.id else {
            dismissPublisher.send()
            return
        }
        
        Task {
            await setRandomPetToMainPet(gachaResultId)
            dismissPublisher.send()
        }
    }
    
    func tapDisMissButton() {
        dismissPublisher.send()
    }
    
    private func selectRandomPet() async {
        let randomPetResult = await homeRepository.addNewGachaRandomPet()
        switch randomPetResult {
        case .success(let pet):
            await MainActor.run {
                gachaResult = pet
            }
        case .failure(let error):
            print("랜덤 펫 생성에 실패했습니다 \(error.localizedDescription)")
        }
    }

    
    private func setRandomPetToMainPet(_ petId: String) async {
        let setMainPetResult = await homeRepository.updateMainPet(petId: petId)
        switch setMainPetResult {
        case .success(let pet):
            break
        case .failure(let error):
            print("메인 펫 설정에 실패했습니다 \(error.localizedDescription)")
        }
    }
}
