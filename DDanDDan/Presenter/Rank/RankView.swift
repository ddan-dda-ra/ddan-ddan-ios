//
//  RankView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/1/25.
//

import SwiftUI

import ComposableArchitecture

struct RankView: View {
    @Perception.Bindable var store: StoreOf<RankViewReducer>
    @ObservedObject var coordinator: AppCoordinator
    
    init(store: StoreOf<RankViewReducer>, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack).edgesIgnoringSafeArea(.all)
            VStack {
                WithPerceptionTracking {
                    Text("월간 랭킹")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 13)
                    CustomTabView(store: Store(
                        initialState: TabFeature.State(),
                        reducer: { TabFeature() })
                    ) { tab in
                        WithPerceptionTracking {
                            RankContentsView(tabType: tab, store: store)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            store.send(.onAppear)
            store.send(.setDateCirteria)
        }
    }
}

//#Preview {
//    RankView(
//        store: Store(
//            initialState: RankFeature.State(selectedTab: .kcal),
//            reducer: {
//                RankFeature()
//            }
//        ), coordinator: .init())
//}

