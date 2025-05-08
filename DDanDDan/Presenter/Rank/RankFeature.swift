//
//  RankFeature.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import ComposableArchitecture

@Reducer
struct RankFeature {
    let repository = RankRepository()
    
    @ObservableState
    struct State: Equatable {
        var kcalRanking: RankInfo?
        var goalRanking: RankInfo?
        
        var cachedRanking: CachedRankInfo?
        
        var totalKcalRanking: Int?
        var totalGoalRanking: Int?
        
        var isKcalRankingLoaded = false
        var isGoalRankingLoaded = false
        
        var isLoading: Bool = false
        var errorMessage: String?
        var showToast: Bool = false
        var toastMessage: String = ""
        
        var showToolKit:Bool = false
        
        var focusedMyRankIndex: Int? = nil
        
        // 데이터가 이미 로드되었는지 추적하는 상태 추가
        var isInitialLoadCompleted = false
    }
    
    enum Action: Equatable {
        case onAppear
        case loadRanking
        case rankingLoaded(kcal: RankInfo, goal: RankInfo)
        case setKcalRanking(RankInfo)
        case setGoalRanking(RankInfo)
        case setLoading(Bool)
        case setError(String?)
        case setShowToast(Bool, String)
        case setShowToolkit
        case focusMyRank(index: Int)
        case cacheRankData
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 이미 데이터가 로드되었으면 아무것도 하지 않음
                if state.isInitialLoadCompleted {
                    return .none
                }
                
                // 캐시된 데이터가 있는지 확인
                if let cachedData = UserDefaults.cachedRanking {
                    state.cachedRanking = cachedData
                    state.kcalRanking = cachedData.kcalRanking
                    state.goalRanking = cachedData.goalRanking
                    state.isKcalRankingLoaded = true
                    state.isGoalRankingLoaded = true
                    state.totalKcalRanking = cachedData.kcalRanking.ranking.last?.rank
                    state.totalGoalRanking = cachedData.goalRanking.ranking.last?.rank
                    
                    // 캐시된 데이터를 사용하고 백그라운드에서 새로운 데이터 로드
                    return .send(.loadRanking)
                } else {
                    state.isLoading = true
                    return .send(.loadRanking)
                }
                
            case .loadRanking:
                // 캐시된 데이터가 없는 경우에만 로딩 표시
                if !state.isKcalRankingLoaded && !state.isGoalRankingLoaded {
                    state.isLoading = true
                }
                
                return .run { send in
                    async let kcal = repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
                    async let goal = repository.getRanking(criteria: .TOTAL_SUCCEEDED_DAYS, period: .MONTHLY)

                    let (kResult, gResult) = await (kcal, goal)

                    switch (kResult, gResult) {
                    case let (.success(k), .success(g)):
                        await send(.rankingLoaded(kcal: k, goal: g))
                        
                        let cachedInfo = CachedRankInfo(
                            kcalRanking: k,
                            goalRanking: g
                        )
                        UserDefaults.cachedRanking = cachedInfo
                        
                    case let (.failure(e), _), let (_, .failure(e)):
                        await send(.setError(e.description))
                    }
                }
                
            case .setKcalRanking(let rankings):
                state.kcalRanking = rankings
                state.totalKcalRanking = rankings.ranking.last?.rank
                state.isKcalRankingLoaded = true
                
                if state.isGoalRankingLoaded {
                    state.isLoading = false
                    state.isInitialLoadCompleted = true
                }
                
                return .none
                
            case .setGoalRanking(let rankings):
                state.goalRanking = rankings
                state.totalGoalRanking = rankings.ranking.last?.rank
                state.isGoalRankingLoaded = true
                
                if state.isKcalRankingLoaded {
                    state.isLoading = false
                    state.isInitialLoadCompleted = true
                }
                
                return .none
                
            case .setLoading(let isLoading):
                state.isLoading = isLoading
                return .none
                
            case .setError(let error):
                state.errorMessage = error
                state.isLoading = false
                return .none
                
            case let .setShowToast(showToast, toastMessage):
                state.showToast = showToast
                state.toastMessage = toastMessage
                if showToast {
                    return .run { send in
                        try await Task.sleep(nanoseconds: 2_500_000_000) // 2초 후
                        await send(.setShowToast(false, ""))
                    }
                }
                return .none
                
            case .setShowToolkit:
                state.showToolKit.toggle()
                return .none
                
            case let .focusMyRank(index):
                state.focusedMyRankIndex = index
                return .none

            case .rankingLoaded(kcal: let kcal, goal: let goal):
                return .concatenate(.send(.setKcalRanking(kcal)), .send(.setGoalRanking(goal)))
                
            case .cacheRankData:
                if let kcal = state.kcalRanking, let goal = state.goalRanking {
                    let cachedInfo = CachedRankInfo(
                        kcalRanking: kcal,
                        goalRanking: goal
                    )
                    UserDefaults.cachedRanking = cachedInfo
                    state.cachedRanking = cachedInfo
                }
                return .none
            }
        }
    }
}
