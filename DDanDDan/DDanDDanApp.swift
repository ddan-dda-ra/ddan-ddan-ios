//
//  DDanDDanApp.swift
//  DDanDDan
//
//  Created by hwikang on 6/28/24.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct DDanDDanApp: App {
    @StateObject var user = UserManager.shared
    @StateObject private var appCoordinator = AppCoordinator()
    private let watchConnection = WatchConnectivityManager.shared
    
    init() {
        KakaoSDK.initSDK(appKey: Config.kakaoKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .environmentObject(user)
                .onOpenURL { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                        AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var user: UserManager
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            switch coordinator.rootView {
            case .splash:
                SplashView(viewModel: SplashViewModel(coordinator: coordinator, homeRepository: HomeRepository()))
            case .signUp:
                SignUpTermView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: coordinator)
            case .home:
                HomeView(coordinator: coordinator, viewModel: .init(repository: HomeRepository(), userInfo: coordinator.userInfo, petInfo: coordinator.petInfo))
            case .onboarding:
                OnboardingView(coordinator: coordinator)
            case .login:
                LoginView(viewModel: LoginViewModel(repository: LoginRepository(), appCoordinator: coordinator))
            }
        }
    }
}

