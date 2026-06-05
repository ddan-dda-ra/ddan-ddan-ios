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

    /// 가챠 의존성을 주입해 초기화한다.
    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }

    /// "선택하기" 버튼 핸들러. 랜덤 펫 가챠를 실행한다.
    /// 진행 중(`isGachaInProgress`)이면 따닥(중복 호출)을 무시한다.
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


    /// "키우기" 버튼 핸들러. 뽑은 펫을 메인 펫으로 설정한다.
    /// 진행 중(`isGrowupInProgress`)이면 따닥(중복 호출)을 무시한다.
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
    
    /// "닫기" 버튼 핸들러. 가챠 화면을 닫는다.
    func tapDisMissButton() {
        dismissPublisher.send()
        isSelectedRandomPet = false
    }

    /// 가챠 API를 호출해 새 랜덤 펫을 받아 `gachaResult`에 보관한다.
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

    
    /// 주어진 펫 ID를 메인 펫으로 설정하는 API를 호출한다.
    private func setRandomPetToMainPet(_ petId: String) async {
        let setMainPetResult = await homeRepository.updateMainPet(petId: petId)
        switch setMainPetResult {
        case .success(let pet):
            await PetArchiveCache.shared.invalidate()
        case .failure(let error):
            print("메인 펫 설정에 실패했습니다 \(error.localizedDescription)")
        }
    }
}
