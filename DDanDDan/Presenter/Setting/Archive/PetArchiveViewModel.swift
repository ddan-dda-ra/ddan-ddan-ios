//
//  PetArchieveViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 11/8/24.
//

import SwiftUI
import HealthKit

final class PetArchiveViewModel: ObservableObject {
    private let homeRepository: HomeRepositoryProtocol
    private let cache: PetArchiveCache
    private var firstSelectedIndex: Int? = nil

    @Published var petList: [Pet] = []
    @Published var selectedIndex: Int? = nil
    @Published var petId: String = ""
    @Published var isSelectedMainPet: Bool = false
    /// 변경된 메인 펫 정보 — 홈에 petType/level을 즉시 동기 반영하기 위해 보관.
    @Published private(set) var selectedMainPet: Pet? = nil
    @Published var showToast = false
    @Published var gridItemCount: Int = 9
    @Published var toastMessage: String = "새로운 펫을 준비 중이에요!"



    var isButtonDisable: Bool {
        guard let firstSelectedIndex, let selectedIndex else { return true }
        return firstSelectedIndex == selectedIndex
    }

    init(repository: HomeRepositoryProtocol, cache: PetArchiveCache = .shared) {
        self.homeRepository = repository
        self.cache = cache
    }

    func setSelectedPet() {
        for (index, pet) in petList.enumerated() {
            if pet.id == UserDefaultValue.petId {
                selectedIndex = index
                break
            }
        }
    }

    func toggleSelection(for index: Int) {
        if selectedIndex == index {
            selectedIndex = nil
        } else {
            selectedIndex = index
        }

        if let selectedPet = petList[safe: index] {
            petId = selectedPet.id
        }
    }

    /// 진입 시 호출: 캐시가 있으면 즉시 UI에 반영(stale-while-revalidate)하고,
    /// 동시에 백그라운드로 최신 데이터를 fetch해 한 번 더 반영한다.
    func fetchPetArchive() async {
        // 1) 캐시 hit이면 즉시 그린다 — placeholder 깜빡임 제거.
        if let cached = await cache.cachedValue() {
            await applyArchive(cached)
        }

        // 2) 백그라운드 갱신(or in-flight join). 캐시가 신선해도 호출하여 stale-while-revalidate를 보장.
        let repo = homeRepository
        let result = await cache.fetch {
            await repo.getPetArchive()
        }
        if case .success(let fresh) = result {
            await applyArchive(fresh)

            if checkIsMaxLevel(pets: fresh.pets) {
                await addNewRandomPet()
            }
        }
    }

    /// 캐시 값/네트워크 응답 어느 쪽이든 동일하게 UI 반영.
    private func applyArchive(_ archive: PetArchiveModel) async {
        await selectedFirstPetIndex(pets: archive.pets)
        UserDefaultValue.userId = archive.ownerUserId
        await updatePetList(with: archive.pets)
    }
    
    @MainActor
    private func selectedFirstPetIndex(pets: [Pet]) {
        selectedIndex = pets.firstIndex {
            $0.id == UserDefaultValue.petId
        }
        firstSelectedIndex = selectedIndex
    }
    
   
    private func checkIsMaxLevel(pets: [Pet]) -> Bool {
        // 모든 펫이 최대치인지 확인
        pets.allSatisfy { $0.expPercent >= 100 && $0.level == 5 }
    }

    private func addNewRandomPet() async {
       let newRandomPet = await homeRepository.addNewRandomPet()
        if case .success(let newPet) = newRandomPet {
            petList.append(newPet)
            // 새 펫이 추가되었으므로 보관함 캐시 무효화 — 다음 진입 시 새 fetch로 stale 회피.
            await cache.invalidate()
        }
    }
    
    private func updatePetList(with pets: [Pet]) async {
        let petCount = pets.count
        let gridItemCount = max(9, Int(ceil(Double(petCount) / 3.0)) * 3)
        
        await MainActor.run { [weak self] in
            self?.petList = pets
            self?.gridItemCount = gridItemCount
        }
    }

    
    func selectMainPet(id: String) async {
        let result = await homeRepository.updateMainPet(petId: id)
        if case .success(let pet) = result {
            UserDefaultValue.petId = pet.mainPet.id
            UserDefaultValue.petType = pet.mainPet.type
            // 메인 펫이 바뀌었으므로 보관함 캐시 무효화 — 다음 진입 시 새 fetch.
            await cache.invalidate()
            await MainActor.run { [weak self] in
                self?.selectedMainPet = pet.mainPet
                self?.isSelectedMainPet = true
            }
        }
    }
    
    func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.hideToastMessage()
        }
    }
    
    func hideToastMessage() {
        showToast = false
    }
}
