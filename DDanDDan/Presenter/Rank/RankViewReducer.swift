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
        var kcalRanking: RankInfo?
        var goalRanking: RankInfo?
        
        var cachedRanking: CachedRankInfo?
        
        var totalKcalRanking: Int?
        var totalGoalRanking: Int?
        
        var isKcalRankingLoaded = false
        var isGoalRankingLoaded = false
        
        var dataLoadingState: DataLoadingState = .initial
        var refreshTrigger: UUID = UUID()
        var isLoading: Bool = false
        var errorMessage: String?
        
        var showToast: Bool = false
        var toastMessage: String = ""
        
        var showToolKit: Bool = false
        
        var focusedMyRankIndex: Int? = nil
        
        var currentTab: Tab = .goal
        
        var kcalLoadingState: DataLoadingState = .initial
        var goalLoadingState: DataLoadingState = .initial
    }
    
    enum DataLoadingState: Equatable {
        case initial
        case loadingFromCache
        case loadingFromNetwork
        case completed
        case failed
    }
    
    enum Action: Equatable {
        case onAppear
        case setCurrentTab(Tab)
        case loadRanking(Tab)
        case loadAllRanking
        case kcalRankingLoaded(RankInfo)
        case goalRankingLoaded(RankInfo)
        case rankingLoaded(kcal: RankInfo, goal: RankInfo)
        case setKcalRanking(RankInfo)
        case setGoalRanking(RankInfo)
        case setLoading(Bool)
        case setError(String?)
        case setShowToast(Bool, String)
        case setShowToolkit
        case focusMyRank(index: Int)
        case cacheRankData
        case refreshData // 뷰 강제 업데이트용
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.dataLoadingState == .completed {
                    return .none
                }
                
                if let cachedData = UserDefaults.cachedRanking {
                    state.dataLoadingState = .loadingFromCache
                    state.kcalLoadingState = .loadingFromCache
                    state.goalLoadingState = .loadingFromCache
                    
                    state.cachedRanking = cachedData
                    state.kcalRanking = cachedData.kcalRanking
                    state.goalRanking = cachedData.goalRanking
                    state.isKcalRankingLoaded = true
                    state.isGoalRankingLoaded = true
                    state.totalKcalRanking = cachedData.kcalRanking.ranking.last?.rank
                    state.totalGoalRanking = cachedData.goalRanking.ranking.last?.rank
                    
                    state.refreshTrigger = UUID()
                    
                    return .send(.loadAllRanking)
                } else {
                    state.isLoading = true
                    state.dataLoadingState = .loadingFromNetwork
                    state.kcalLoadingState = .loadingFromNetwork
                    state.goalLoadingState = .loadingFromNetwork
                    return .send(.loadAllRanking)
                }
                
            case let .setCurrentTab(tab):
                state.currentTab = tab
                
                let needsLoading = switch tab {
                case .kcal:
                    state.kcalRanking == nil || state.kcalLoadingState == .loadingFromCache
                case .goal:
                    state.goalRanking == nil || state.goalLoadingState == .loadingFromCache
                }
                
                if needsLoading {
                    return .send(.loadRanking(tab))
                }
                
                return .none
                
            case let .loadRanking(tab):
                switch tab {
                case .kcal:
                    state.kcalLoadingState = .loadingFromNetwork
                case .goal:
                    state.goalLoadingState = .loadingFromNetwork
                }
                
                return .run { send in
                    switch tab {
                    case .kcal:
                        let result = await repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
                        switch result {
                        case .success(let ranking):
                            await send(.kcalRankingLoaded(ranking))
                        case .failure(let error):
                            await send(.setError(error.description))
                        }
                        
                    case .goal:
                        let result = await repository.getRanking(criteria: .TOTAL_SUCCEEDED_DAYS, period: .MONTHLY)
                        switch result {
                        case .success(let ranking):
                            await send(.goalRankingLoaded(ranking))
                        case .failure(let error):
                            await send(.setError(error.description))
                        }
                    }
                }
                
            case .loadAllRanking:
                if state.dataLoadingState == .loadingFromCache {
                    state.dataLoadingState = .loadingFromNetwork
                    state.kcalLoadingState = .loadingFromNetwork
                    state.goalLoadingState = .loadingFromNetwork
                }
                
                return .run { send in
                    async let kcal = repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
                    async let goal = repository.getRanking(criteria: .TOTAL_SUCCEEDED_DAYS, period: .MONTHLY)

                    let (kResult, gResult) = await (kcal, goal)

                    switch (kResult, gResult) {
                    case let (.success(k), .success(g)):
                        await send(.rankingLoaded(kcal: k, goal: g))
                        
                    case let (.failure(e), _), let (_, .failure(e)):
                        await send(.setError(e.description))
                    }
                }
                
            case let .kcalRankingLoaded(ranking):
                state.kcalRanking = ranking
                state.totalKcalRanking = ranking.ranking.last?.rank
                state.isKcalRankingLoaded = true
                state.kcalLoadingState = .completed
                
                if state.currentTab == .kcal {
                    state.refreshTrigger = UUID()
                }
                
                if let goalRanking = state.goalRanking {
                    let cachedInfo = CachedRankInfo(
                        kcalRanking: ranking,
                        goalRanking: goalRanking
                    )
                    UserDefaults.cachedRanking = cachedInfo
                    state.cachedRanking = cachedInfo
                }
                
                return .none
                
            case let .goalRankingLoaded(ranking):
                state.goalRanking = ranking
                state.totalGoalRanking = ranking.ranking.last?.rank
                state.isGoalRankingLoaded = true
                state.goalLoadingState = .completed
                
                if state.currentTab == .goal {
                    state.refreshTrigger = UUID()
                }
                
                if let kcalRanking = state.kcalRanking {
                    let cachedInfo = CachedRankInfo(
                        kcalRanking: kcalRanking,
                        goalRanking: ranking
                    )
                    UserDefaults.cachedRanking = cachedInfo
                    state.cachedRanking = cachedInfo
                }
                
                return .none
                
            case .rankingLoaded(kcal: let kcal, goal: let goal):
                state.kcalRanking = kcal
                state.goalRanking = goal
                state.totalKcalRanking = kcal.ranking.last?.rank
                state.totalGoalRanking = goal.ranking.last?.rank
                state.isKcalRankingLoaded = true
                state.isGoalRankingLoaded = true
                state.isLoading = false
                state.dataLoadingState = .completed
                state.kcalLoadingState = .completed
                state.goalLoadingState = .completed
                
                state.refreshTrigger = UUID()
                
                let cachedInfo = CachedRankInfo(
                    kcalRanking: kcal,
                    goalRanking: goal
                )
                UserDefaults.cachedRanking = cachedInfo
                state.cachedRanking = cachedInfo
                
                return .none
                
            case .setKcalRanking(let rankings):
                state.kcalRanking = rankings
                state.totalKcalRanking = rankings.ranking.last?.rank
                state.isKcalRankingLoaded = true
                state.kcalLoadingState = .completed
                
                if state.currentTab == .kcal {
                    state.refreshTrigger = UUID()
                }
                
                if state.isGoalRankingLoaded {
                    state.isLoading = false
                    state.dataLoadingState = .completed
                }
                
                return .none
                
            case .setGoalRanking(let rankings):
                state.goalRanking = rankings
                state.totalGoalRanking = rankings.ranking.last?.rank
                state.isGoalRankingLoaded = true
                state.goalLoadingState = .completed
                
                if state.currentTab == .goal {
                    state.refreshTrigger = UUID()
                }
                
                if state.isKcalRankingLoaded {
                    state.isLoading = false
                    state.dataLoadingState = .completed
                }
                
                return .none
                
            case .setLoading(let isLoading):
                state.isLoading = isLoading
                return .none
                
            case .setError(let error):
                state.errorMessage = error
                state.isLoading = false
                state.dataLoadingState = .failed
                
                switch state.currentTab {
                case .kcal:
                    state.kcalLoadingState = .failed
                case .goal:
                    state.goalLoadingState = .failed
                }
                
                return .none
                
            case let .setShowToast(showToast, toastMessage):
                state.showToast = showToast
                state.toastMessage = toastMessage
                if showToast {
                    return .run { send in
                        try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5초 후
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
                
            case .refreshData:
                state.refreshTrigger = UUID()
                return .none
            }
        }
    }
}
