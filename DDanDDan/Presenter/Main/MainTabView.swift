//
//  MainTabView.swift
//  DDanDDan
//
//  Created by keone on 8/15/25.
//

import SwiftUI
import ComposableArchitecture
enum TabType: Int, CaseIterable {
    case home = 0
    case rank = 1
    case friends = 2
    case setting = 3

    var title: String {
        switch self {
        case .home: return "홈"
        case .rank: return "랭킹"
        case .friends: return "친구"
        case .setting: return "마이페이지"
        }
    }
    
    var resource: ImageResource {
        switch self {
        case .home: return .iconTabHome
        case .rank: return .iconTabRank
        case .friends: return .iconTabFriends
        case .setting: return .iconTabSetting
        }
    }
}
struct MainTabView: View {
    let coordinator: AppCoordinator
    
    var body: some View {
        TabView {
            ForEach(TabType.allCases, id: \.self) { tab in
                viewForTab(tab)
                    .tabItem {
                        Image(tab.resource)
                            .renderingMode(.template)
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .tag(tab)
            }
        }
        .accentColor(.white)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.backgroundBlack
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    
    @ViewBuilder
    private func viewForTab(_ tab: TabType) -> some View {
        switch tab {
        case .home:
            HomeView(coordinator: coordinator, viewModel: .init(repository: HomeRepository(), userInfo: coordinator.userInfo, petInfo: coordinator.petInfo))
        case .rank:
            RankView(store: Store(initialState: RankViewReducer.State()) {  RankViewReducer() },
                     coordinator: coordinator)
        case .friends:
            //TODO: 친구목록 연결
            EmptyView()
        case .setting:
            SettingView(coordinator: coordinator, store: Store(initialState: SettingViewReducer.State(), reducer: { SettingViewReducer(repository: SettingRepository()) }))
        }
    }
}
