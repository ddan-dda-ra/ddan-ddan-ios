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
    @Perception.Bindable var store: StoreOf<MainTabReducer>
    @State private var didSetupBindings = false
    
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var newPetViewModel = NewPetViewModel()
    @StateObject private var randomGachaPetViewModel = RandomGachaPetViewModel(homeRepository: HomeRepository())
    
    init(coordinator: AppCoordinator, store: StoreOf<MainTabReducer>) {
        self.coordinator = coordinator
        self.store = store
        
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            repository: HomeRepository(),
            userInfo: coordinator.userInfo,
            petInfo: coordinator.petInfo
        ))
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                // Content Area
                Group {
                    viewForTab(store.selectedTab)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Toast View
                if store.showToast {
                    TransparentOverlayView(isPresented: store.showToast, isDimView: false) {
                        VStack {
                            ToastView(message: store.toastMessage, toastType: .info)
                        }
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 180.adjustedHeight)
                    }
                }
                
                // Friend Card Overlay
                if store.friendCard != nil || store.rankState.friendCard != nil || store.friendsState.friendCard != nil {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    if let mainCardStore = store.scope(state: \.friendCard, action: \.friendCard.presented) {
                        FriendCardView(store: mainCardStore)
                            .transition(.opacity)
                    } else if let rankCardStore = store.scope(state: \.rankState.friendCard, action: \.rank.friendCard.presented) {
                        FriendCardView(store: rankCardStore)
                            .transition(.opacity)
                    } else if let friendCardStore = store.scope(state: \.friendsState.friendCard, action: \.friends.friendCard.presented) {
                        FriendCardView(store: friendCardStore)
                            .transition(.opacity)
                    }
                }
                
                // Custom Rounded TabBar
                RoundedTabBar(selectedTab: $store.selectedTab)
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: store.friendCard != nil || store.rankState.friendCard != nil || store.friendsState.friendCard != nil)
            .onAppear {
                if !didSetupBindings {
                    setupViewModelBindings()
                    didSetupBindings = true
                }
            }
            .onReceive(coordinator.$petChangedSession) { _ in
                store.send(.petChanged)
            }
            .onReceive(NotificationCenter.default.publisher(for: .friendInviteDeepLink)) { notification in
                if let inviteCode = notification.object as? String {
                    store.send(.handleDeepLink(inviteCode: inviteCode))
                }
            }
            .onChange(of: store.navigateToFriendAdd) { newValue in
                if let friend = newValue {
                    DispatchQueue.main.async {
                        coordinator.push(to: HomePath.addFriend(
                            level: friend.friendUser.petLevel,
                            petType: friend.friendUser.mainPetType
                        ))
                        store.send(.clearNavigateToFriendAdd)
                    }
                }
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
                    NewPetView(coordinator: coordinator, viewModel: newPetViewModel)
                case .upgradePet(let level, let petType, let newPet):
                    LevelUpView(coordinator: coordinator, level: level, petType: petType, newRandomPet: newPet)
                case .addFriend(level: let level, petType: let petType):
                    FriendAddView(coordinator: coordinator, level: level, petType: petType)
                }
            }
        }
    }
    
    private func setupViewModelBindings() {
        homeViewModel.bind(overlayVM: newPetViewModel)
        homeViewModel.bind(overlayVM: randomGachaPetViewModel)
    }
    
    @ViewBuilder
    private func viewForTab(_ tab: TabType) -> some View {
        let tabBarHeight: CGFloat = 65
        
        switch tab {
        case .home:
            HomeView(
                coordinator: coordinator,
                viewModel: homeViewModel,
                newPetViewModel: newPetViewModel,
                randomGachaPetViewModel: randomGachaPetViewModel
            )
        case .rank:
            RankView(
                store: store.scope(state: \.rankState, action: \.rank),
                coordinator: coordinator
            )
            .padding(.bottom, tabBarHeight)
        case .friends:
            FriendListView(
                store: store.scope(state: \.friendsState, action: \.friends),
                coordinator: coordinator
            )
            .padding(.bottom, tabBarHeight)
        case .setting:
            SettingView(
                coordinator: coordinator,
                store: store.scope(state: \.settingState, action: \.setting)
            )
            .padding(.bottom, tabBarHeight)
        }
    }
}

struct RoundedTabBar: View {
    @Binding var selectedTab: TabType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabType.allCases, id: \.self) { tab in
                TabBarButton(
                    icon: tab.resource,
                    title: tab.title,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.backgroundGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderGray, lineWidth: 1)
                )
        )
    }
}

struct TabBarButton: View {
    let icon: ImageResource
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(icon)
                    .renderingMode(.template)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.caption1_semiBold11)
            }
            .padding(.vertical, 4)
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
    }
}

// NotificationCenter 확장
extension Notification.Name {
    static let friendInviteDeepLink = Notification.Name("friendInviteDeepLink")
}
