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
                    CustomTabView(
                        store: Store(initialState: TabFeature.State(), reducer: { TabFeature() }), views: [
                            .kcal: AnyView(RankContentsView(tabType: .kcal)),
                            .goal:  AnyView(RankContentsView(tabType: .goal))
                        ]
                    )
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

#Preview {
    RankView(
        store: Store(initialState: RankFeature.State(),
                     reducer: {
                         RankFeature()
                     }), coordinator: .init())
}
