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
        .navigationDestination(for: SettingPath.self) { path in
            switch path {
            case .petArchive:
                PetArchiveView(coordinator: coordinator, viewModel: PetArchiveViewModel(repository: HomeRepository()))
            case .updateNickname:
                UpdateNicknameView(coordinator: coordinator,
                                   store: Store(initialState: UpdateNicknameReducer.State(),
                                                reducer: { UpdateNicknameReducer(repository: SettingRepository())}))
            case .updateCalorie:
                UpdateCalorieView(coordinator: coordinator, store: Store(initialState: UpdateCalorieReducer.State(),
                                                                         reducer: { UpdateCalorieReducer(repository: SettingRepository()) }))
            case .updateTerms:
                SettingTermView(coordinator: coordinator)
            case .deleteUser:
                DeleteUserView(coordinator: coordinator, store: Store(initialState: DeleteUserReducer.State(), reducer: { DeleteUserReducer(repository: SettingRepository()) }))
            case .deleteUserConfirm(let store):
                DeleteUserConfirmView(coordinator: coordinator, store: store)
            default:
                EmptyView()
            }
        }
        .navigationDestination(for: HomePath.self) { path in
            switch path {
            case .successThreeDay(let totalKcal):
                ThreeDaySuccessView(coordinator: coordinator, totalKcal: totalKcal)
            case .newPet:
                NewPetView(coordinator: coordinator, viewModel: NewPetViewModel(homeRepository: HomeRepository(), coordinator: coordinator))
            case .upgradePet(let level, let petType):
                LevelUpView(coordinator: coordinator, level: level, petType: petType)
            }
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
