//
//  RankFeature.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RankViewReducer {
    let repository = RankRepository()
    
    @ObservableState
    struct State: Equatable {
        // Ranking Data
        var kcalRanking: RankInfo?
        var goalRanking: RankInfo?
        var rankDateCirteria: String = ""
        
        var cachedRanking: CachedRankInfo?
        
        var totalKcalRanking: Int?
        var totalGoalRanking: Int?
        
        var dataLoadingState: DataLoadingState = .initial
        var kcalLoadingState: DataLoadingState = .initial
        var goalLoadingState: DataLoadingState = .initial
        
        var errorMessage: String?
        
        var focusedMyRankIndex: Int?
        
        var currentTab: Tab = .goal
        
        // UI
        var showToast: Bool = false
        var toastMessage: String = ""
        
        var showToolKit: Bool = false
        
        // Scope
        @Presents var friendCard: FriendCardReducer.State?
        
    }
    
    enum DataLoadingState: Equatable {
        case initial
        case loadingFromCache
        case loadingFromNetwork
        case completed
        case failed
    }
    
    enum Action {
        case onAppear
        case tabChanged(Tab)
        case tabItem(Ranking)
        case refreshTapped
        case errorDismissed
        
        case rankingResponse(TaskResult<TabRanking>)
        case singleRankingResponse(Tab, TaskResult<RankInfo>)
        case setDateCirteria
        
        case focusMyRank(index: Int)
        case showToast(String)
        case toastTimerCompleted
        case toolkitButtonTapped
        
        //Scope
        case friendCard(PresentationAction<FriendCardReducer.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return handleonAppeared(&state)
            case let .tabChanged(tab):
                return handleTabChanged(&state, tab: tab)
            case .refreshTapped:
                return handleRefresh(&state)
            case .errorDismissed:
                state.errorMessage = nil
                return .none
            case let .rankingResponse(result):
                return handleRankingResponse(&state, result: result)
            case let .singleRankingResponse(tab, result):
                return handleSingleRankingResponse(&state, tab: tab, result: result)
            case .setDateCirteria:
                state.rankDateCirteria = setDateCirteria()
                return .none
            case let .focusMyRank(index: index):
                state.focusedMyRankIndex = index
                return .none
            case let .showToast(message):
                return handleShowToast(&state, message: message)
            case .toastTimerCompleted:
                state.showToast = false
                state.toastMessage = ""
                return .none
            case .toolkitButtonTapped:
                state.showToolKit.toggle()
                return .none
            case let .tabItem(rank):
                state.friendCard = .init(entity: transformFriendCardEntity(rank: rank), type: .cheer)
                return .none
            case .friendCard:
                return .none
            }
        }
        .ifLet(\.$friendCard, action: \.friendCard) {
            FriendCardReducer()
        }
    }
}

private extension RankViewReducer {
    func handleonAppeared(_ state: inout State) -> Effect<Action> {
        guard state.dataLoadingState != .completed else { return .none }
        
        // 캐시가 있으면 캐시 로딩 상태로 설정
        if let cachedData = UserDefaults.cachedRanking {
            loadFromCache(&state, cachedData: cachedData)
        } else {
            setNetworkLoading(&state)
        }
        
        return loadAllRanking()
    }
    
    func handleTabChanged(_ state: inout State, tab: Tab) -> Effect<Action> {
        state.currentTab = tab
        
        // 해당 탭의 데이터가 없거나 캐시 상태면 로딩 필요
        let needsLoading = switch tab {
        case .kcal:
            state.kcalRanking == nil || state.kcalLoadingState == .loadingFromCache
        case .goal:
            state.goalRanking == nil || state.goalLoadingState == .loadingFromCache
        }
        
        return needsLoading ? loadSingleRanking(tab) : .none
    }
    
    func handleRefresh(_ state: inout State) -> Effect<Action> {
        // 현재 탭만 새로고침
        setTabLoading(&state, tab: state.currentTab)
        return loadSingleRanking(state.currentTab)
    }
    
    func handleRankingResponse(_ state: inout State, result: TaskResult<TabRanking>) -> Effect<Action> {
        switch result {
        case let .success(TabRanking):
            setBothRankingData(&state, kcal: TabRanking.kcal, goal: TabRanking.goal)
            cacheRankingData(&state, kcal: TabRanking.kcal, goal: TabRanking.goal)
            setAllCompleted(&state)
            return .none
            
        case let .failure(error):
            setError(&state, message: error.localizedDescription)
            return .none
        }
    }
    
    func handleSingleRankingResponse(_ state: inout State, tab: Tab, result: TaskResult<RankInfo>) -> Effect<Action> {
        switch result {
        case let .success(ranking):
            setRankingData(&state, tab: tab, ranking: ranking)
            cacheIfBothLoaded(&state)
            return .none
            
        case let .failure(error):
            setTabError(&state, tab: tab, message: error.localizedDescription)
            return .none
        }
    }
    
    func handleShowToast(_ state: inout State, message: String) -> Effect<Action> {
        state.showToast = true
        state.toastMessage = message
        
        return .run { send in
            try await Task.sleep(nanoseconds: 2_500_000_000)
            await send(.toastTimerCompleted)
        }
    }
    
    func setDateCirteria() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 기준"
        
        let dateCriteria = dateFormatter.string(from: Date())
        return dateCriteria
    }
    
    func transformFriendCardEntity(rank: Ranking) -> FriendCardEntity {
        .init(userID: rank.userID, userName: rank.userName, mainPetType: rank.mainPetType, petLevel: rank.petLevel, totalCalories: rank.totalCalories, cheerCount: 1234) //TODO: cheerCount 수정
    }
}

// MARK: - Effect Creators
private extension RankViewReducer {
    
    func loadAllRanking() -> Effect<Action> {
        return .run { send in
            await send(.rankingResponse(
                TaskResult {
                    async let kcal = repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
                    async let goal = repository.getRanking(criteria: .TOTAL_SUCCEEDED_DAYS, period: .MONTHLY)
                    
                    let (kResult, gResult) = await (kcal, goal)
                    
                    switch (kResult, gResult) {
                    case let (.success(k), .success(g)):
                        return (TabRanking(kcal: k, goal: g))
                    case let (.failure(e), _), let (_, .failure(e)):
                        throw e
                    }
                }
            ))
        }
    }
    
    func loadSingleRanking(_ tab: Tab) -> Effect<Action> {
        return .run { send in
            let criteria: CriteriaType = tab == .kcal ? .TOTAL_CALORIES : .TOTAL_SUCCEEDED_DAYS
            
            await send(.singleRankingResponse(
                tab,
                TaskResult {
                    try await repository.getRanking(criteria: criteria, period: .MONTHLY).get()
                }
            ))
        }
    }
}

private extension RankViewReducer {
    
    func loadFromCache(_ state: inout State, cachedData: CachedRankInfo) {
        state.dataLoadingState = .loadingFromCache
        state.kcalLoadingState = .loadingFromCache
        state.goalLoadingState = .loadingFromCache
        state.cachedRanking = cachedData
        state.kcalRanking = cachedData.kcalRanking
        state.goalRanking = cachedData.goalRanking
        state.totalKcalRanking = cachedData.kcalRanking.ranking.last?.rank
        state.totalGoalRanking = cachedData.goalRanking.ranking.last?.rank
    }
    
    func setNetworkLoading(_ state: inout State) {
        state.dataLoadingState = .loadingFromNetwork
        state.kcalLoadingState = .loadingFromNetwork
        state.goalLoadingState = .loadingFromNetwork
    }
    
    func setTabLoading(_ state: inout State, tab: Tab) {
        switch tab {
        case .kcal: state.kcalLoadingState = .loadingFromNetwork
        case .goal: state.goalLoadingState = .loadingFromNetwork
        }
    }
    
    func setBothRankingData(_ state: inout State, kcal: RankInfo, goal: RankInfo) {
        state.kcalRanking = kcal
        state.goalRanking = goal
        state.totalKcalRanking = kcal.ranking.last?.rank
        state.totalGoalRanking = goal.ranking.last?.rank
    }
    
    func setRankingData(_ state: inout State, tab: Tab, ranking: RankInfo) {
        switch tab {
        case .kcal:
            state.kcalRanking = ranking
            state.totalKcalRanking = ranking.ranking.last?.rank
            state.kcalLoadingState = .completed
        case .goal:
            state.goalRanking = ranking
            state.totalGoalRanking = ranking.ranking.last?.rank
            state.goalLoadingState = .completed
        }
    }
    
    func setAllCompleted(_ state: inout State) {
        state.dataLoadingState = .completed
        state.kcalLoadingState = .completed
        state.goalLoadingState = .completed
    }
    
    func setError(_ state: inout State, message: String) {
        state.errorMessage = message
        state.dataLoadingState = .failed
        state.kcalLoadingState = .failed
        state.goalLoadingState = .failed
    }
    
    func setTabError(_ state: inout State, tab: Tab, message: String) {
        state.errorMessage = message
        switch tab {
        case .kcal: state.kcalLoadingState = .failed
        case .goal: state.goalLoadingState = .failed
        }
    }
    
    func cacheRankingData(_ state: inout State, kcal: RankInfo, goal: RankInfo) {
        let cachedInfo = CachedRankInfo(kcalRanking: kcal, goalRanking: goal)
        UserDefaults.cachedRanking = cachedInfo
        state.cachedRanking = cachedInfo
    }
    
    func cacheIfBothLoaded(_ state: inout State) {
        guard let kcal = state.kcalRanking, let goal = state.goalRanking else { return }
        cacheRankingData(&state, kcal: kcal, goal: goal)
    }
}
