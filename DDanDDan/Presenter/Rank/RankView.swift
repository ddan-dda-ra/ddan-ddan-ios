//
//  RankView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/1/25.
//

import SwiftUI

import ComposableArchitecture

struct RankView: View {
    @Perception.Bindable var store: StoreOf<RankFeature>
    @ObservedObject var coordinator: AppCoordinator
    
    init(store: StoreOf<RankFeature>, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
            VStack {
                WithPerceptionTracking {
                    CustomNavigationBar(
                        title: "월간 랭킹",
                        leftButtonImage: Image(.arrow)) {
                            coordinator.pop()
                        }
                    
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
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            store.send(.onAppear)
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
