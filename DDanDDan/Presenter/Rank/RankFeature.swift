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
        var isLoading: Bool = false
        var errorMessage: String?
    }
    
    enum Action: Equatable {
        case selectTab(Tab)
        case loadKcalRanking
        case loadGoalRanking
        case setKcalRanking(RankInfo)
        case setGoalRanking(RankInfo)
        case setLoading(Bool)
        case setError(String?)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectTab(tab):
                state.selectedTab = tab
                return .run { send in
                    await tab == .kcal ? send(.loadKcalRanking) : send(.loadGoalRanking)
                }
            case .loadKcalRanking:
                state.isLoading = true
                return .run { send in
                    let result = await repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
                    
                    switch result {
                    case .success(let rank):
                        await send(.setKcalRanking(rank))
                    case .failure(let failure):
                        await send(.setError(failure.description))
                    }
                }
                
            case .loadGoalRanking:
                state.isLoading = true
                return .run { send in
                    let result = await repository.getRanking(criteria: .TOTAL_CALORIES, period: .MONTHLY)
                    
                    switch result {
                    case .success(let rank):
                        await send(.setGoalRanking(rank))
                    case .failure(let failure):
                        await send(.setError(failure.description))
                    }
                }
            case .setKcalRanking(let rankings):
                state.kcalRanking = rankings
                state.isLoading = false
                return .none
                
            case .setGoalRanking(let rankings):
                state.goalRanking = rankings
                state.isLoading = false
                return .none
                
            case .setLoading(let isLoading):
                state.isLoading = isLoading
                return .none
                
            case .setError(let error):
                state.errorMessage = error
                state.isLoading = false
                
                return .none
            }
        }
        
    }
}
