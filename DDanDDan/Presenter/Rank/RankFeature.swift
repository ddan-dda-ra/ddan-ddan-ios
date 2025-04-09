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
        var totalRankCount: Int?
        
        var isKcalRankingLoaded = false
        var isGoalRankingLoaded = false
        
        var isLoading: Bool = false
        var errorMessage: String?
        var showToast: Bool = false
        var toastMessage: String = ""
    }
    
    enum Action: Equatable {
        case onAppear
        case loadRanking
        case setKcalRanking(RankInfo)
        case setGoalRanking(RankInfo)
        case setLoading(Bool)
        case setError(String?)
        case setShowToast(Bool, String)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .send(.loadRanking)
            case .loadRanking:
                return .merge(
                    fetchGoalRanking(),
                    fetchKcalRanking()
                )
            case .setKcalRanking(let rankings):
                state.kcalRanking = rankings
                state.totalRankCount = rankings.ranking.count
                state.isKcalRankingLoaded = true
                return (state.isGoalRankingLoaded ? .send(.setLoading(false)) : .none)
            case .setGoalRanking(let rankings):
                state.goalRanking = rankings
                state.isGoalRankingLoaded = true
                return (state.isKcalRankingLoaded ? .send(.setLoading(false)) : .none)
            case .setLoading(let isLoading):
                state.isLoading = isLoading
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
