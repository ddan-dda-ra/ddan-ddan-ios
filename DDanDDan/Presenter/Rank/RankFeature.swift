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
        var selectedTab: Tab = .kcal
        var kcalRanking: RankInfo?
        var goalRanking: RankInfo?
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

    }
    
    enum Action: Equatable {
        case onAppear
        case setTab(Tab)
        case loadRanking
        case rankingLoaded(kcal: RankInfo, goal: RankInfo)
        case setKcalRanking(RankInfo)
        case setGoalRanking(RankInfo)
        case setLoading(Bool)
        case setError(String?)
        case setShowToast(Bool, String)
        case setShowToolkit
        case focusMyRank(index: Int)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print(state)
                state.isLoading = true
                return .send(.loadRanking)
            case let .setTab(tab):
                state.selectedTab = tab
                return .none
            case .loadRanking:
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
            case .setKcalRanking(let rankings):
                state.kcalRanking = rankings
                state.totalKcalRanking = rankings.ranking.last?.rank
                state.isKcalRankingLoaded = true
                
                return (state.isGoalRankingLoaded ? .send(.setLoading(false)) : .none)
            case .setGoalRanking(let rankings):
                state.goalRanking = rankings
                state.totalGoalRanking = rankings.ranking.last?.rank
                state.isGoalRankingLoaded = true
                
                return (state.isKcalRankingLoaded ? .send(.setLoading(false)) : .none)
            case .setLoading(let isLoading):
                state.isLoading = isLoading
                print(state)
                
                return .none
            case .setError(let error):
                
                state.errorMessage = error
                
                return .send(.setLoading(false))
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
                return .concatenate(.send(.setKcalRanking(kcal)),  .send(.setGoalRanking(goal)))
            }
        }
    }
    
    private func fetchKcalRanking() -> Effect<Action> {
        return .run { send in
            let result = await repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
            
            switch result {
            case .success(let rank):
                await send(.setKcalRanking(rank))
            case .failure(let failure):
                await send(.setError(failure.description))
            }
        }
    }
    
    private func fetchGoalRanking() -> Effect<Action> {
        return .run { send in
            let result = await repository.getRanking(criteria: .TOTAL_SUCCEEDED_DAYS, period: .MONTHLY)
            
            switch result {
            case .success(let rank):
                await send(.setGoalRanking(rank))
            case .failure(let failure):
                await send(.setError(failure.description))
            }
        }
    }
    
}
