//
//  RankView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/1/25.
//

import SwiftUI

import ComposableArchitecture

struct RankView: View {
    let store: StoreOf<RankFeature>
    @ObservedObject var coordinator: AppCoordinator
    
    init(store: StoreOf<RankFeature>, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.backgroundBlack)
                VStack {
                    CustomNavigationBar(
                        title: "월간 랭킹",
                        leftButtonImage: Image(.arrow)) {
                            coordinator.pop()
                        }
                    WithPerceptionTracking {
                        CustomTabView(
                            store: Store(
                                initialState: TabFeature.State(),
                                reducer: { TabFeature() }
                            ),
                            views: [
                                .kcal: AnyView(RankContentsView(tabType: .kcal, store: store)),
                                .goal: AnyView(RankContentsView(tabType: .goal, store: store))
                            ]
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.all, edges: .bottom)
            .task {
                store.send(.onAppear)
            }
        }
    }
}

#Preview {
    RankView(
        store: Store(
            initialState: RankFeature.State(selectedTab: .kcal),
            reducer: {
                RankFeature()
            }
        ), coordinator: .init())
}
