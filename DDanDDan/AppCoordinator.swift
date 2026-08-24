//
//  AppCoordinator.swift
//  DDanDDan
//
//  Created by 이지희 on 11/7/24.
//

import SwiftUI

import Combine

enum AppPath: Hashable {
    case splash
    case signUp
    case mainTab
    case onboarding
    case login
}

/// 메인 펫 변경 시 홈에 즉시 반영할 새 펫 정보.
struct PetChangePayload: Equatable {
    let petType: String
    let level: Int
    let expPercent: Double
}

final class AppCoordinator: ObservableObject {
    // 루트뷰
    @Published var rootView: AppPath = .splash
    
    // 스플래쉬에서 미리 받을 정보
    @Published var userInfo: HomeUserInfo? = nil
    @Published var petInfo: MainPet? = nil
    
    // 네비게이션 경로를 저장하는 프로퍼티
    @Published var navigationPath = NavigationPath()
    // 시트를 표시하기 위한 뷰를 저장하는 프로퍼티
    @Published var sheetView: AnyView?
    
    @StateObject var user = UserManager.shared
    
    @Published private(set) var shouldUpdateHomeView = false
    @Published private(set) var petChangedSession: UUID = UUID()

    /// 메인 펫 변경 시, 새 펫 정보(petType/level)를 홈에 즉시 동기 반영하기 위한 페이로드.
    /// fetchHomeInfo() 비동기 완료를 기다리지 않고 배경/펫이 바로 새것으로 표시되도록 한다.
    @Published private(set) var pendingPetChange: PetChangePayload?

    @MainActor
    func triggerPetChanged(payload: PetChangePayload? = nil) {
        if let payload {
            pendingPetChange = payload
        }
        petChangedSession = UUID()
    }

    /// 페이로드를 1회 소비한다. 새 sink가 attach될 때 latched된 옛 payload가
    /// 다시 발화되어 stale로 회귀하는 것을 막기 위함.
    @MainActor
    func consumePendingPetChange() {
        pendingPetChange = nil
    }

    func setRoot(to path: AppPath) {
        Task { @MainActor in
            navigationPath.removeLast(navigationPath.count)
            rootView = path
        }
    }

    /// 인증 bootstrap 결과를 한 MainActor transaction에서 반영한다.
    /// Splash가 반환된 뒤에도 이전 root가 남는 비동기 전환 구간을 만들지 않는다.
    @MainActor
    func commitAuthenticatedBootstrap(userInfo: HomeUserInfo, petInfo: MainPet) {
        self.userInfo = userInfo
        self.petInfo = petInfo
        navigationPath.removeLast(navigationPath.count)
        rootView = .mainTab
    }
    
    func pop() {
        navigationPath.removeLast()
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func push(to path: SignUpPath) {
        navigationPath.append(path)
    }
    
    func push(to path: SettingPath) {
        navigationPath.append(path)
    }
    
    func push(to path: HomePath) {
        navigationPath.append(path)
    }
    
    func triggerHomeUpdate(trigger: Bool) {
        shouldUpdateHomeView = trigger
    }
    
}
