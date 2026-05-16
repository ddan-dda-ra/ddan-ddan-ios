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
    /// 가챠 API 진행 중 플래그. 따닥 방지(in-flight guard) 및 버튼 비활성화 바인딩에 사용.
    @Published var isGachaInProgress: Bool = false
    /// 메인 펫 설정 API 진행 중 플래그.
    @Published var isGrowupInProgress: Bool = false

    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }

    func tapSelectButton() {
        guard !isGachaInProgress else { return }
        isGachaInProgress = true
        gachaResult = nil

        Task {
            await selectRandomPet()
            await MainActor.run {
                if gachaResult != nil {
                    isSelectedRandomPet = true
                }
                isGachaInProgress = false
            }
        }
    }


    func tapGrowupButton() {
        guard !isGrowupInProgress else { return }
        guard let gachaResultId = gachaResult?.id else {
            return
        }
        isGrowupInProgress = true

        Task { @MainActor in
            await setRandomPetToMainPet(gachaResultId)
            isSelectedRandomPet = false
            isGrowupInProgress = false
            dismissPublisher.send()
        }
    }
    
    func tapDisMissButton() {
        dismissPublisher.send()
        isSelectedRandomPet = false
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
