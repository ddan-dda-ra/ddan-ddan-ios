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
        case onAppear
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
            case .onAppear:
                state.isLoading = true
                print("onAppear")
                return .concatenate(
                    .send(.loadKcalRanking),
                    .send(.loadGoalRanking)
                )
            case .loadKcalRanking:
                print("loadKcalRanking")
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
                print("loadGoalRanking")
                state.isLoading = true
                return .run { send in
                    let result = await repository.getRanking(criteria: .TOTAL_SUCCEEDED_DAYS, period: .MONTHLY)
                    
                    switch result {
                    case .success(let rank):
                        await send(.setGoalRanking(rank))
                    case .failure(let failure):
                        await send(.setError(failure.description))
                    }
                }
            case .setKcalRanking(let rankings):
                print("setKcalRanking")
                state.kcalRanking = rankings
                state.isLoading = false
                return .none
                
            case .setGoalRanking(let rankings):
                print("setGoalRanking")
                state.goalRanking = rankings
                state.isLoading = false
                return .none
                
            case .setLoading(let isLoading):
                print("setLoading")
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
