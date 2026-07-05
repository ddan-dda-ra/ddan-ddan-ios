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


@MainActor
final class HomeViewModel: ObservableObject {
    
    private struct Loading {
        var feed: Bool = false
    }
    
    @Published var homePetModel: HomeModel = .init(
        petType: UserDefaultValue.petType,
        level: UserDefaultValue.level,
        exp: 0,
        goalKcal: UserDefaultValue.purposeKcal,
        feedCount: 0,
        toyCount: 0,
        ticket: 0
    )
    
    @Published var isPlayingSpecialAnimation: Bool = false
    @Published var currentLottieAnimation: String = ""
    @Published private(set) var petPresentation: PetPresentation = .resolve(
        petType: UserDefaultValue.petType,
        petLevel: UserDefaultValue.level,
        snapshot: .empty
    )
    
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
    @Published var showCalorieTooltip: Bool = false

    @Published var enableRandomPet: Bool = false
    @Published var showRandomPetGuide: Bool = false
    @Published var showRandomGachaView: Bool = false

    /// 홈 진입 코치마크 (먹이주기 → 놀아주기 순서)
    @Published var showFeedCoachMark: Bool = false
    @Published var showPlayCoachMark: Bool = false
    
    let homeRepository: HomeRepositoryProtocol
    
    private var petId = ""
    private var previousKcal: Int = 0
    private var cancellables = Set<AnyCancellable>()
    private let catalogStore: PetCatalogStore
    private var calorieTooltipToken: UUID?
    private var didAutoShowCalorieTooltip = false
    private var hasSeenHealthKitAuthorized = false
    /// foreground 단발 re-read의 연타 방지용 시간 가드(2초). observer/init read와는 무관.
    private var lastForegroundReadAt: Date?
    
    private var loadingState: Loading = Loading()
    private let healthKitManager = HealthKitManager.shared
    
    private let generator = UIImpactFeedbackGenerator(style: .heavy)
    
    init(
        repository: HomeRepositoryProtocol,
        userInfo: HomeUserInfo? = nil,
        petInfo: MainPet? = nil,
        catalogStore: PetCatalogStore = .shared
    ) {
        self.homeRepository = repository
        self.catalogStore = catalogStore
        
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
            
            enableRandomPet = userInfo.tickets > 0
        }

        catalogStore.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.resolvePresentation() }
            .store(in: &cancellables)
        resolvePresentation()
        
        observeHealthKitData()
    }
    
    @MainActor
    func updateLottieAnimation(for action: LottieMode) async throws {
        guard !isPlayingSpecialAnimation else { return }
        
        isPlayingSpecialAnimation = true
        currentLottieAnimation = action == .eatPlay ? "remote-play-eat" : "remote-default"

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
    
    /// 메인 펫 변경 시 새 petType/level/exp를 홈 상태에 즉시 동기 반영한다.
    /// fetchHomeInfo() 완료를 기다리지 않으므로 이전 펫이 잠깐 보이는 stale 깜빡임을 막는다.
    ///
    /// 펫 시각화에 필요한 petType/level/exp만 즉시 반영하며,
    /// feedCount/toyCount/ticket/goalKcal/currentKcal 등 나머지 정보는
    /// 이어 호출되는 fetchHomeInfo()가 일괄 덮어쓴다. 이 사이의 짧은 윈도우에서
    /// 위 카운트 필드들이 이전 값일 수 있다.
    @MainActor
    func applyPetChange(petType: String, level: Int, expPercent: Double) {
        homePetModel.petType = petType
        homePetModel.level = level
        homePetModel.exp = expPercent
        // 변경 직후 이전 펫 애니메이션이 남지 않도록 특수 애니메이션 상태를 초기화한다.
        isPlayingSpecialAnimation = false
        currentLottieAnimation = ""
        resolvePresentation()
    }

    @MainActor
    func fetchHomeInfo() async {
        
        let userData = await homeRepository.getUserInfo()
        let mainPetData = await homeRepository.getMainPetInfo()
        
        if case .success(let userInfo) = userData,
           case .success(let petInfo) = mainPetData {
            UserDefaultValue.userId = userInfo.id
            UserDefaultValue.petType = petInfo.mainPet.type
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
            resolvePresentation()
            
            let info: [String: Any] = [
                "purposeKcal": userInfo.purposeCalorie,
                "petType": petInfo.mainPet.type,
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
                try await playFeedPet(petData: petData, bubble: .eat)
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
                try await playFeedPet(petData: petData, bubble: .play)
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
    private func playFeedPet(petData: UserPetData, bubble: bubbleTextType) async throws {
        let interaction = HomePetInteractionReducer.reduce(
            response: .init(
                petID: petData.pet.id,
                petType: petData.pet.type,
                level: petData.pet.level,
                expPercent: petData.pet.expPercent,
                foodQuantity: petData.user.foodQuantity,
                toyQuantity: petData.user.toyQuantity
            ),
            catalog: catalogStore.snapshot
        )

        self.homePetModel.toyCount = interaction.toyQuantity
        self.homePetModel.feedCount = interaction.foodQuantity
        self.homePetModel.exp = interaction.expPercent
        self.petId = interaction.petID
        UserDefaultValue.petId = interaction.petID
        UserDefaultValue.petType = interaction.petType
        
        UserDefaultValue.level = petData.pet.level
        
        // 레벨 변화 확인
        if self.homePetModel.level != interaction.level {
            self.homePetModel.level = interaction.level
            self.isLevelUp = true
            self.isPlayingSpecialAnimation = false
            
            if interaction.level == 5 {
                self.isPlayingSpecialAnimation = false
                self.isMaxLevel = true
            }
            
        }

        self.homePetModel.petType = interaction.petType
        self.petPresentation = interaction.presentation

        self.showRandomBubble(type: bubble)
        try await self.updateLottieAnimation(for: .eatPlay)
    }

    @MainActor
    private func resolvePresentation() {
        petPresentation = PetPresentation.resolve(
            petType: homePetModel.petType,
            petLevel: homePetModel.level,
            snapshot: catalogStore.snapshot
        )
    }
    
    
    // MARK: - HealthKit
    
    private func observeHealthKitData() {
        healthKitManager.observeActiveEnergyBurned { [weak self] newKcal, authorized in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.applyHealthKitResult(newKcal: Int(newKcal), authorized: authorized, source: .observerCallback)
            }
        }
    }

    /// observe 콜백 / foreground 단발 re-read 양쪽에서 호출하는 공용 적용 헬퍼.
    /// sticky 권한 갱신 + 표시값(currentKcal) 적용 + 서버 전송 + 권한 미허용 툴팁 + 이상 판정을 담당한다.
    /// HealthKit 콜백은 이미 main으로 들어오므로 @MainActor 컨텍스트에서만 호출한다.
    @MainActor
    private func applyHealthKitResult(newKcal: Int, authorized: Bool, source: HealthKitReadSource) {
        // 한 번이라도 허용이 관측되면 세션 내에서 유지(sticky).
        // read 권한 데이터가 일시적으로 비는 구간에서도 권한 상태가 false로
        // 되돌아가 i 아이콘이 깜빡이는 UI 플리커를 방지한다.
        if authorized {
            self.hasSeenHealthKitAuthorized = true
            self.isHealthKitAuthorized = true
        } else if !self.hasSeenHealthKitAuthorized {
            self.isHealthKitAuthorized = false
        }

        // 0 깜빡임 가드: "권한 없음 + 0"인 일시적 빈 결과로는 화면값을 0으로 덮지 않는다(이전 표시값 유지).
        // 권한 OK면 무운동(0)·자정 리셋도 정상 반영. (App Group 저장 가드와 동일 의미를 표시값에도 적용)
        if authorized || newKcal > 0 {
            self.currentKcal = newKcal
        }
        // 서버 경로는 무변경: 가드와 무관하게 원래 newKcal을 그대로 전달.
        // foreground 단발 re-read는 값이 실제로 바뀐 경우에만 부작용(서버 전송/말풍선)을 발생시킨다.
        // (init/observer 경로는 기존과 동일하게 무조건 호출 — 동작 불변)
        if source == .foregroundReRead {
            if newKcal != previousKcal {
                self.handleKcalUpdate(newKcal: newKcal)
            }
        } else {
            self.handleKcalUpdate(newKcal: newKcal)
        }

        // i 아이콘이 뜨는 케이스(권한 없음)에 한해, 최초 판단 시 1회 자동 노출
        if !self.isHealthKitAuthorized && !self.didAutoShowCalorieTooltip {
            self.didAutoShowCalorieTooltip = true
            self.showCalorieTooltipMessage()
        }

        // 이상 최종 판정(맥락 의존): "전엔 권한 있었는데 지금 비는" observer_gap.
        // foreground/observer 경로만 대상. 정상0(권한 OK)·첫 진입 미허용은 무발생.
        if source != .initRead,
           self.hasSeenHealthKitAuthorized,
           !authorized,
           newKcal == 0 {
            AnalyticsManager.shared.logEvent(event: HealthKitEvent.observerGap(source: source.rawValue))
        }
    }

    /// scenePhase .active 진입 시 호출. observer를 재등록하지 않고 단발 read만 수행한다.
    /// 짧은 시간 내 .active 연타(제어센터/알림센터 스와이프 등)에 대비해 2초 시간 가드를 둔다.
    @MainActor
    func refreshActiveEnergyIfNeeded() {
        let now = Date()
        if let last = lastForegroundReadAt, now.timeIntervalSince(last) < 2 { return }
        lastForegroundReadAt = now

        healthKitManager.refreshActiveEnergy(source: .foregroundReRead) { [weak self] kcal, authorized in
            guard let self else { return }
            // refreshActiveEnergy → readActiveEnergyBurned는 이미 main으로 콜백하지만,
            // @MainActor 헬퍼 호출 보장을 위해 main 컨텍스트에서 적용한다.
            DispatchQueue.main.async {
                self.applyHealthKitResult(newKcal: Int(kcal), authorized: authorized, source: .foregroundReRead)
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
    
    /// HealthKit 권한 확인 및 요청 (앱 첫 진입 시 다이얼로그 트리거 용도).
    /// 실제 권한 상태(isHealthKitAuthorized)는 observeActiveEnergyBurned 콜백에서 갱신된다.
    private func checkHealthKitAuthorization() {
        if !healthKitManager.isAuthorized() {
            healthKitManager.requestAuthorization { _ in }
        }
    }
    
    // MARK: CoachMark View
    
    @MainActor
    func bind(overlayVM: NewPetViewModel) {
        overlayVM.dismissPublisher
            .sink { [weak self] in
                guard let self else { return }
                // 티켓 증가 및 UI 즉시 반영
                self.homePetModel.ticket += 1
                self.enableRandomPet = true
                
                // 서버 데이터와 동기화
                Task {
                    await self.fetchHomeInfo()
                    await MainActor.run {
                        self.showRandomPetCoachMark()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func showRandomPetCoachMark() {
        withAnimation {
            enableRandomPet = true
        }

        // 최대 레벨에서 돌아올 때 체크
        if UserDefaultValue.isFirstRandomTicket {
            UserDefaultValue.isFirstRandomTicket = false

           // 첫 랜덤 가챠일 경우 표출
            withAnimation(.easeInOut(duration: 0.6)) {
                showRandomPetGuide = true
            }
        }
    }

    /// 홈 진입 시 신규 사용자에게 먹이/놀이 코치마크 시작.
    /// 가챠 코치마크와 동시 노출되지 않도록 가드.
    @MainActor
    func startHomeCoachMarkIfNeeded() {
        guard UserDefaultValue.isFirstHomeCoachMarkShown else { return }
        guard !showRandomPetGuide else { return }
        UserDefaultValue.isFirstHomeCoachMarkShown = false
        withAnimation(.easeInOut(duration: 0.6)) {
            showFeedCoachMark = true
        }
    }

    /// "다음" → 먹이 코치마크 닫고 놀이 코치마크 노출
    @MainActor
    func tapFeedCoachMarkNext() {
        AnalyticsManager.shared.logEvent(event: HomeEvent.clickFeedCoachMarkNext)
        withAnimation(.easeInOut(duration: 0.6)) {
            showFeedCoachMark = false
            showPlayCoachMark = true
        }
    }

    /// "시작하기" → 놀이 코치마크 닫기. 추가 동작 없음.
    @MainActor
    func tapPlayCoachMarkStart() {
        AnalyticsManager.shared.logEvent(event: HomeEvent.clickPlayCoachMarkStart)
        withAnimation(.easeInOut(duration: 0.6)) {
            showPlayCoachMark = false
        }
    }
    
    
    
    // MARK: Random Gacha Pet
    
    @MainActor
    func bind(overlayVM: RandomGachaPetViewModel) {
        overlayVM.dismissPublisher
            .sink { [weak self] in
                guard let self else { return }
                // 뷰 닫기
                self.showRandomGachaView = false
                
                // 티켓 차감 및 UI 즉시 반영
                if self.homePetModel.ticket > 0 {
                    self.homePetModel.ticket -= 1
                }
                self.enableRandomPet = self.homePetModel.ticket > 0
                
                // 서버 데이터와 동기화
                Task {
                    await self.fetchHomeInfo()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func tapRandomGachaButton() {
        withAnimation(.easeInOut(duration: 0.6)) {
            showRandomPetGuide = false
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

    /// 칼로리 안내 툴팁을 노출하고 2.5초 후 자동으로 닫는다.
    /// 노출 중 다시 호출되면 timer가 리셋되어 다시 2.5초 카운트.
    /// token 패턴으로 이전 timer가 새 노출을 종료하지 않도록 보호.
    @MainActor
    func showCalorieTooltipMessage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCalorieTooltip = true
        }

        let token = UUID()
        calorieTooltipToken = token

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.calorieTooltipToken == token else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showCalorieTooltip = false
            }
            self.calorieTooltipToken = nil
        }
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
