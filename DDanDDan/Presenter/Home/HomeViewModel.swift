//
//  HomeViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI
import UIKit
import Combine

import HealthKit


final class HomeViewModel: ObservableObject {
    
    private struct Loading {
        var feed: Bool = false
    }
    
    @Published var homePetModel: HomeModel = .init(
        petType: PetType(rawValue: UserDefaultValue.petType) ?? .pinkCat,
        level: UserDefaultValue.level,
        exp: 0,
        goalKcal: UserDefaultValue.purposeKcal,
        feedCount: 0,
        toyCount: 0,
        ticket: 0
    )
    
    @Published var isPlayingSpecialAnimation: Bool = false
    @Published var currentLottieAnimation: String = ""
    
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
    
    @Published var showToolTipView: Bool = false
    
    @Published var enableRandomPet: Bool = false
    @Published var showRandomGachaView: Bool = false
    
    private var petId = ""
    private var previousKcal: Int = 0
    private var cancellables = Set<AnyCancellable>()
    
    private var loadingState: Loading = Loading()
    private let healthKitManager = HealthKitManager.shared
    private let homeRepository: HomeRepositoryProtocol
    
    private let generator = UIImpactFeedbackGenerator(style: .heavy)
    
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
                toyCount: userInfo.toyQuantity,
                ticket: userInfo.tickets
            )
            
            self.petId = petInfo.mainPet.id
        }
        
        observeHealthKitData()
    }
    
    @MainActor
    func updateLottieAnimation(for action: LottieMode) async throws {
        guard !isPlayingSpecialAnimation else { return }
        
        isPlayingSpecialAnimation = true
        currentLottieAnimation = homePetModel.petType.lottieString(level: homePetModel.level, mode: action)

        // 햅틱
        let hapticDuration: Double = 1.0
        let interval: UInt64 = 100_000_000
        let repeatCount = Int(hapticDuration / (Double(interval) / 1_000_000_000))
        
        for _ in 0..<repeatCount {
            generator.impactOccurred(intensity: 1.0)
            try await Task.sleep(nanoseconds: interval)
        }
        
        
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                self?.isPlayingSpecialAnimation = false
                self?.currentLottieAnimation = ""
                continuation.resume()
            }
        }
        
        generator.prepare()
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
                toyCount: userInfo.toyQuantity,
                ticket: userInfo.tickets
            )
            
            enableRandomPet = userInfo.tickets > 0
            
            let info: [String: Any] = [
                "purposeKcal": userInfo.purposeCalorie,
                "petType": petInfo.mainPet.type.rawValue,
                "level": petInfo.mainPet.level
            ]
            
            WatchConnectivityManager.shared.transferUserInfo(info: info)
            
            
        }
    }
    
    /// 먹이주기
    func feedPet() {
        guard homePetModel.feedCount > 0 else {
            toastMessage = "먹이가 부족해요!"
            generator.impactOccurred()
            showToastMessage()
            return
        }
        loadingState.feed = true
        Task {
            let result = await homeRepository.feedPet(petId: petId)
            loadingState.feed = false
            switch result {
            case let .success(petData):
                try await playFeedPet(petData: petData)
            case let .failure(error) :
                await failToPlayWithPet(error: error)
            }
        }
    }
    
    /// 놀아주기
    func playWithPet() {
        guard homePetModel.toyCount > 0 else {
            toastMessage = "장난감이 부족해요!"
            generator.impactOccurred()
            showToastMessage()
            return
        }
        
        Task {
            let result = await homeRepository.playPet(petId: petId)
            switch result {
            case let .success(petData):
                try await playFeedPet(petData: petData)
            case let .failure(error) :
                await failToPlayWithPet(error: error)
            }
        }
    }
    
    @MainActor
    private func failToPlayWithPet(error: NetworkError) {
        switch error {
        case .serverError(_, let code):
            generator.impactOccurred()
            toastMessage = code == "PE003" ? "성장이 끝난 펫이에요!" : "오류가 발생했습니다: \(code)"
        default: break
        }
        showToastMessage()
    }
    
    @MainActor
    private func playFeedPet(petData: UserPetData) async throws {
        
        self.homePetModel.toyCount = petData.user.toyQuantity
        self.homePetModel.feedCount = petData.user.foodQuantity
        self.homePetModel.exp = petData.pet.expPercent
        
        
        // 레벨 변화 확인
        if self.homePetModel.level != petData.pet.level {
            self.homePetModel.level = petData.pet.level
            self.isLevelUp = true
            self.isPlayingSpecialAnimation = false
        }
        
        if petData.pet.level == 4 && petData.pet.expPercent == 100 && !isMaxLevel {
            self.isPlayingSpecialAnimation = false
            self.isMaxLevel = true
        }
        
        self.showRandomBubble(type: .play)
        try await self.updateLottieAnimation(for: .eatPlay)
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
                
                self.earnFood = dailyInfo.rewardedFoodQuantity
                self.isPresentEarnFood = self.earnFood > 0 /// 얻은 먹이가 양수일 때만 다이얼로그 띄움
                
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
            }
        }
    }
    
    /// HealthKit 권한 확인 및 요청
    private func checkHealthKitAuthorization() {
        if !healthKitManager.isAuthorized() {
            healthKitManager.requestAuthorization { _ in }
        }
    }
    
    // MARK: CoachMark View
    
    func bind(overlayVM: NewPetViewModel) {
        overlayVM.dismissPublisher
            .sink { [weak self] in
                self?.showRandomPetCoachMark()
            }
            .store(in: &cancellables)
    }
    
    private func showRandomPetCoachMark() {
        // 최대 레벨에서 돌아올 때 체크
        if UserDefaultValue.isFirstRandomTicket {
            UserDefaultValue.isFirstRandomTicket = false
            
           // 첫 랜덤 가챠일 경우 표출
            withAnimation(.easeInOut(duration: 0.6)) {
                enableRandomPet.toggle()
            }
        }
    }
    
    
    
    // MARK: Random Gacha Pet
    
    func bind(overlayVM: RandomGachaPetViewModel) {
        overlayVM.dismissPublisher
            .sink { [weak self] in
                self?.showRandomGachaView = false
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func tapRandomGachaButton() {
        withAnimation(.easeInOut(duration: 0.6)) {
            enableRandomPet = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.6)) {
                self.showRandomGachaView = true
            }
        }
    }
    // MARK: - Toast & Bubble
    
    @MainActor
    func showRandomBubble(type: bubbleTextType) {
        // 이전 말풍선이 없을 때만 보이도록
        if showBubble == false {
            
            generator.impactOccurred(intensity: 1.0)
            
            self.bubbleImage = type.getRandomText().randomElement() ?? .default1
            
            withAnimation {
                self.showBubble = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.showBubble = false
                }
            }
        }
    }
    
    @MainActor
    func showTooltipView() {
        showToolTipView.toggle()
    }
    
    
    /// 토스트 메시지 관련 메서드
    private func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.hideToastMessage()
            }
        }
    }
    
    private func hideToastMessage() {
        showToast = false
    }
}
