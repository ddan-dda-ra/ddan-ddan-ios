//
//  HomeViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI
import UIKit

import HealthKit


final class HomeViewModel: ObservableObject {
    @Published var homePetModel: HomeModel = .init(petType: .pinkCat, level: 2, exp: 0, goalKcal: 0, feedCount: 0, toyCount: 0)
    
    @Published var isPlayingSpecialAnimation: Bool = false

    @Published var currentLottieAnimation: String = ""
    @Published var isDailyGoalMet: Bool = false
    @Published var isGoalMet: Bool = false
    @Published var isMaxLevel: Bool = false
    @Published var isLevelUp: Bool = false
    
    @Published var isHealthKitAuthorized: Bool = true // 초기값은 true로 설정
    @Published var currentKcal = 0
    @Published var threeDaysTotalKcal: Int = 0
    
    @Published var earnFood: Int = 0
    @Published var isPresentEarnFood: Bool = false
    
    @Published var bubbleImage: ImageResource = .default1
    @Published var showBubble: Bool = false
    
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    
    private var petId = ""
    private var previousKcal: Int = 0
    
    private let healthKitManager = HealthKitManager.shared
    private let homeRepository: HomeRepositoryProtocol
    
    init(
        repository: HomeRepositoryProtocol,
        userInfo: HomeUserInfo? = nil,
        petInfo: MainPet? = nil
    ) {
        self.homeRepository = repository
        
        // 권한 체크
        checkHealthKitAuthorization()
        
        // 스플래쉬에서 받아오는 정보들
        if let userInfo = userInfo, let petInfo = petInfo {
            self.homePetModel = HomeModel(
                petType: petInfo.mainPet.type,
                level: petInfo.mainPet.level,
                exp: Double(petInfo.mainPet.expPercent),
                goalKcal: userInfo.purposeCalorie,
                feedCount: userInfo.foodQuantity,
                toyCount: userInfo.toyQuantity
            )
            
            self.petId = petInfo.mainPet.id
        }
        
        observeHealthKitData()
    }
    
    func updateLottieAnimation(for action: LottieMode) {
        guard !isPlayingSpecialAnimation else { return } // 이미 애니메이션이 재생 중인 경우 무시
        
        isPlayingSpecialAnimation = true
        currentLottieAnimation = homePetModel.petType.lottieString(level: homePetModel.level, mode: action)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self else { return }
            self.isPlayingSpecialAnimation = false
            self.currentLottieAnimation = "" // 초기 상태로 복구
        }
    }
    
    @MainActor
    func fetchHomeInfo() async {
        
        let userData = await homeRepository.getUserInfo()
        let mainPetData = await homeRepository.getMainPetInfo()
        
        if case .success(let userInfo) = userData,
           case .success(let petInfo) = mainPetData {
            UserDefaultValue.userId = userInfo.id
            UserDefaultValue.petType = petInfo.mainPet.type.rawValue
            UserDefaultValue.petId = petInfo.mainPet.id
            UserDefaultValue.purposeKcal = userInfo.purposeCalorie
            
            self.petId = petInfo.mainPet.id
            self.homePetModel = HomeModel(
                petType: petInfo.mainPet.type,
                level: petInfo.mainPet.level,
                exp: Double(petInfo.mainPet.expPercent),
                goalKcal: userInfo.purposeCalorie,
                feedCount: userInfo.foodQuantity,
                toyCount: userInfo.toyQuantity
            )
            
            let info: [String: Any] = [
                "purposeKcal": userInfo.purposeCalorie,
                "petType": petInfo.mainPet.type.rawValue,
                "level": petInfo.mainPet.level
            ]
            
            WatchConnectivityManager.shared.transferUserInfo(info: info)
            
        }
    }
    
    /// 먹이주기
    func feedPet() async {
        guard homePetModel.feedCount > 0 else {
            DispatchQueue.main.async { [weak self] in
                self?.toastMessage = "먹이가 부족해요!"
              self?.triggerHapticFeedback(style: .warning)
                self?.showToastMessage()
            }
            return
        }
        
        let result = await homeRepository.feedPet(petId: petId)
        if case .success(let petData) = result {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.updateLottieAnimation(for: .eatPlay)
                
                self.showRandomBubble(type: .eat)
                self.homePetModel.feedCount = petData.user.foodQuantity
                self.homePetModel.exp = petData.pet.expPercent
                
                self.triggerHapticFeedback(style: .success)
                
                // 레벨 변화 확인
                if self.homePetModel.level != petData.pet.level {
                    self.homePetModel.level = petData.pet.level
                    self.isLevelUp = true
                }
                
                if petData.pet.level == 5 && petData.pet.expPercent == 100 && !isMaxLevel {
                    self.isMaxLevel = true
                }
            }
        } else if case .failure(let error) = result {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch error {
                case .serverError(_, let code):
                    if code == "PE003" {
                        self.toastMessage = "성장이 끝난 펫이에요!"
                        self.triggerHapticFeedback(style: .error)
                    } else {
                        self.toastMessage = "오류가 발생했습니다: \(code)"
                    }
                case .dataNil, .encodingError, .failToDecode, .invalidResponse, .requestFailed, .urlError:
                    break
                }
                self.showToastMessage()
            }
        }
    }
    
    /// 놀아주기
    func playWithPet() async {
        guard homePetModel.toyCount > 0 else {
            DispatchQueue.main.async { [weak self] in
                self?.toastMessage = "장난감이 부족해요!"
                self?.showToastMessage()
                self?.triggerHapticFeedback(style: .error)
            }
            return
        }
        
        let result = await homeRepository.playPet(petId: petId)
        if case .success(let petData) = result {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.updateLottieAnimation(for: .eatPlay)
                self.showRandomBubble(type: .play)
                self.homePetModel.toyCount = petData.user.toyQuantity
                self.homePetModel.exp = petData.pet.expPercent
                
                self.triggerHapticFeedback(style: .success)
                
                // 레벨 변화 확인
                if self.homePetModel.level != petData.pet.level {
                    self.homePetModel.level = petData.pet.level
                    self.isLevelUp = true
                }
                
                if petData.pet.level == 5 && petData.pet.expPercent == 100 && !isMaxLevel {
                    self.isMaxLevel = true
                }
            }
        } else if case .failure(let error) = result {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch error {
                case .serverError(_, let code):
                    if code == "PE003" {
                        self.toastMessage = "성장이 끝난 펫이에요!"
                        self.triggerHapticFeedback(style: .error)
                    } else {
                        self.toastMessage = "오류가 발생했습니다: \(code)"
                    }
                case .dataNil, .encodingError, .failToDecode, .invalidResponse, .requestFailed, .urlError:
                    break
                }
                self.showToastMessage()
            }
        }
    }
    
    
    // MARK: - HealthKit
    
    private func observeHealthKitData() {
        healthKitManager.observeActiveEnergyBurned { [weak self] newKcal in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentKcal = Int(newKcal)
                self.handleKcalUpdate(newKcal: Int(newKcal))
            }
        }
    }
    
    /// 서버 전송 - 칼로리 업데이트 시
    private func handleKcalUpdate(newKcal: Int) {
        let kcalDifference = (newKcal % 100) - (previousKcal % 100)
        
        Task {
            await saveCurrentKcal(currentKcal: newKcal)
        }
        previousKcal = newKcal
        
        if newKcal >= homePetModel.goalKcal {
            DispatchQueue.main.async { [weak self] in
                self?.showRandomBubble(type: .success)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showRandomBubble(type: .failure)
            }
        }
    }
    
    /// 현재 칼로리 저장
    private func saveCurrentKcal(currentKcal: Int) async {
        let result = await homeRepository.updateDailyKcal(calorie: currentKcal)
        
        if case .success(let dailyInfo) = result {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                /// 현재 먹이 개수와 다르면 먹이 얻기
                if self.homePetModel.feedCount != dailyInfo.user.foodQuantity {
                    if dailyInfo.user.foodQuantity - self.homePetModel.feedCount == 3 {
                        self.isDailyGoalMet = true
                    } else {
                        self.earnFood = dailyInfo.user.foodQuantity - self.homePetModel.feedCount
                        self.isPresentEarnFood = self.earnFood > 0 /// 얻은 먹이가 양수일 때만 다이얼로그 띄움
                    }
                }
                
                if self.homePetModel.toyCount != dailyInfo.user.toyQuantity {
                    healthKitManager.readThreeDaysTotalKcal { [weak self] totalKcal in
                        guard let self else { return }
                        DispatchQueue.main.async {
                            self.threeDaysTotalKcal = Int(totalKcal)
                            self.isGoalMet = dailyInfo.user.toyQuantity - self.homePetModel.toyCount > 0
                        }
                    }
                }
                
                self.homePetModel.feedCount = dailyInfo.user.foodQuantity
                self.homePetModel.toyCount = dailyInfo.user.toyQuantity
                
                UserDefaultValue.currentKcal = Double(dailyInfo.dailyInfo.calorie)
                UserDefaultValue.date = dailyInfo.dailyInfo.date.toDate() ?? Date()
            }
        }
    }
    
    /// HealthKit 권한 확인 및 요청
    private func checkHealthKitAuthorization() {
        if !healthKitManager.isAuthorized() {
            healthKitManager.requestAuthorization { _ in }
        }
    }
    
    // MARK: - Toast & Bubble
    
    @MainActor
    func showRandomBubble(type: bubbleTextType) {
        // 이전 말풍선이 없을 때만 보이도록
        if showBubble == false {
            self.bubbleImage = type.getRandomText().randomElement() ?? .default1
            
            withAnimation {
                self.showBubble = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showBubble = false
                }
            }
        }
    }
    
    
    /// 토스트 메시지 관련 메서드
    private func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hideToastMessage()
        }
    }
    
    private func hideToastMessage() {
        showToast = false
    }
    
    
    private func triggerHapticFeedback(style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }

}
