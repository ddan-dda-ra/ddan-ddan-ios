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
        
        // HomeViewModel 초기화
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            repository: HomeRepository(),
            userInfo: coordinator.userInfo,
            petInfo: coordinator.petInfo
        ))
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                TabView(selection: $store.selectedTab) {
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
                .fullScreenCover(
                    store: store.scope(state: \.$friendCard, action: \.friendCard)
                ) { store in
                    FriendCardView(store: store)
                }
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
                
                // Toast View
                if store.showToast {
                    TransparentOverlayView(isPresented: store.showToast, isDimView: false) {
                        VStack {
                            ToastView(message: store.toastMessage, toastType: .info)
                        }
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 240.adjustedHeight)
                    }
                }
            }
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.backgroundBlack
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance

                if !didSetupBindings {
                    setupViewModelBindings()
                    didSetupBindings = true
                }
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
        switch tab {
        case .home:
            HomeView(
                coordinator: coordinator,
                viewModel: homeViewModel,
                newPetViewModel: newPetViewModel,
                randomGachaPetViewModel: randomGachaPetViewModel
            )
        case .rank:
            RankView(store: Store(initialState: RankViewReducer.State()) {  RankViewReducer(repository: RankRepository()) },
                     coordinator: coordinator)
        case .friends:
            FriendListView(
                store: Store(initialState: FriendsViewReducer.State()) {
                    FriendsViewReducer()
                },
                coordinator: coordinator
            )
        case .setting:
            SettingView(coordinator: coordinator, store: Store(initialState: SettingViewReducer.State(), reducer: { SettingViewReducer(repository: SettingRepository()) }))
        }
    }
}

// NotificationCenter 확장
extension Notification.Name {
    static let friendInviteDeepLink = Notification.Name("friendInviteDeepLink")
}
