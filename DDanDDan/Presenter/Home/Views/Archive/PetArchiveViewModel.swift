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
    
    @Published var petList: [Pet] = []
    @Published var selectedIndex: Int? = nil
    @Published var petId: String = ""
    @Published var isSelectedMainPet: Bool = false
    @Published var showToast = false
    @Published var gridItemCount: Int = 9
    
    
    init(repository: HomeRepositoryProtocol) {
        self.homeRepository = repository
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
    
    func fetchPetArchive() async {
        let petArchiveModel = await homeRepository.getPetArchive()
        
        if case .success(let petArchive) = petArchiveModel {
            UserDefaultValue.userId = petArchive.ownerUserId
            await updatePetList(with: petArchive.pets)
            
            // 모든 펫의 level과 exp가 최대치인지 확인 후 새로운 펫 추가
            if checkIsMaxLevel(pets: petArchive.pets) {
                await addNewRandomPet()
            }
        }
    }
    
   
    private func checkIsMaxLevel(pets: [Pet]) -> Bool {
        // 모든 펫이 최대치인지 확인
        pets.allSatisfy { $0.expPercent >= 100 && $0.level == 5 }
    }

    private func addNewRandomPet() async {
       let newRandomPet = await homeRepository.addNewRandomPet()
        if case .success(let newPet) = newRandomPet {
            petList.append(newPet)
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
            UserDefaultValue.petType = pet.mainPet.type.rawValue
            DispatchQueue.main.async { [weak self] in
                self?.isSelectedMainPet = true
            }
        }
    }
    
    func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hideToastMessage()
        }
    }
    
    func hideToastMessage() {
        showToast = false
    }
}
