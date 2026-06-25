//
//  SettingView.swift
//  DDanDDan
//
//  Created by hwikang on 9/10/24.
//

import SwiftUI
import UIKit
import ComposableArchitecture

enum SettingPath: Hashable, CaseIterable {
    static var allCases: [SettingPath] {
        [.petArchive, .updateNickname, .updateCalorie, .notification, .inquiry, .updateTerms, .deleteUser, .logout]
    }
    
    static var myInfoSection: [SettingPath] { [.petArchive, .updateNickname, updateCalorie] }
    static var notificationSection: [SettingPath] { [.notification] }
    static var bottomSection: [SettingPath] { [.inquiry, .updateTerms, .deleteUser, .logout] }
    
    case petArchive
    case updateNickname
    case updateCalorie
    case notification
    case inquiry
    case updateTerms
    case deleteUser
    case deleteUserConfirm(store: StoreOf<DeleteUserReducer>)
    case logout
    
    var title: String {
        switch self {
        case .petArchive: "펫 보관함"
        case .updateNickname: "내 별명 수정"
        case .updateCalorie: "목표 칼로리 수정"
        case .notification: "전체 푸시 알림"
        case .inquiry: "문의하기"
        case .updateTerms: "약관 및 개인정보 처리 동의"
        case .deleteUser: "탈퇴하기"
        case .logout: "로그아웃"
        default: ""
        }
    }
    var description: String {
        switch self {
        case .petArchive: "같이 운동할 펫을 설정할 수 있어요"
        default: ""
        }
    }
}

struct SettingView: View {
    @ObservedObject public var coordinator: AppCoordinator
    let store: StoreOf<SettingViewReducer>
    
    var appVersion: String {
        if let dictionary = Bundle.main.infoDictionary,
           let version = dictionary["CFBundleShortVersionString"] as? String {
            return version
        } else {
            return "버전 정보 없음"
        }
    }
    
    var body: some View {
        WithViewStore(store) { $0 } content: { viewStore in

            let logoutDialogBinding = viewStore.binding(get: \.showLogoutDialog,
                                                        send: SettingViewReducer.Action.showLogoutDialog)
            let notificationStateBinding = viewStore.binding(get: \.notificationState,
                                                             send: SettingViewReducer.Action.toggleNotification)
            ZStack(alignment: .topLeading) {
                Color.backgroundBlack.edgesIgnoringSafeArea(.all)
                VStack(alignment: .center, spacing: 0) {
                    Text("마이 페이지")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 13)
                    
                    roundButtonSection(title: "내 정보 수정", items: SettingPath.myInfoSection,
                                       notificationState: notificationStateBinding)
                    .padding(.top, 12)
                    
                    roundButtonSection(title: "알림 설정", items: SettingPath.notificationSection,
                                       notificationState: notificationStateBinding)
                    .padding(.top, 16)
                    
                    SectionView(items: SettingPath.bottomSection,
                                showLogoutDialog: logoutDialogBinding,
                                coordinator: coordinator)
                    
                    Text("앱 버전 \(appVersion)")
                        .font(.body3_regular12)
                        .foregroundStyle(.iconGray)
                        .frame(height: 46)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                }
                .transparentFullScreenCover(isPresented: logoutDialogBinding) {
                    
                    DialogView(show: logoutDialogBinding,
                               title: "정말 로그아웃 하시겠습니까?", description: "", rightButtonTitle: "로그아웃", leftButtonTitle: "취소") {
                        Task {
                            await UserManager.shared.logout()
                            coordinator.triggerHomeUpdate(trigger: true)
                            coordinator.setRoot(to: .login)
                        }
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)

                // 펫 보관함 진입 체감 로딩을 줄이기 위한 prefetch.
                // TTL/in-flight 가드는 캐시 내부에서 처리한다.
                Task {
                    await PetArchiveCache.shared.prefetchIfNeeded {
                        await HomeRepository().getPetArchive()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    
    @ViewBuilder
    func roundButtonSection(title: String, items: [SettingPath], notificationState: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .foregroundStyle(.textBodyTeritary)
                .font(.body2_regular14)
                .padding(.bottom, 12)
            ForEach(items, id:\.self) { section in
                WithPerceptionTracking {
                    RoundButtonSectionItem(item: section, coordinator: coordinator, notificationState: notificationState)
                        .padding(.bottom, 12)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}


extension SettingView {
    
    struct RoundButtonSectionItem: View {
        let item: SettingPath
        let coordinator: AppCoordinator
        @Binding var notificationState: Bool
        
        var body: some View {
            Button(action: {
                
                handleAction(for: item)
            }, label: {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .foregroundStyle(.textHeadlinePrimary)
                            .font(.heading6_semibold16)
                        if !item.description.isEmpty {
                            Text(item.description)
                                .foregroundStyle(.textBodyTeritary)
                                .font(.body2_regular14)
                        }
                    }
                    Spacer()
                    if item == .notification {
                        Toggle(isOn: $notificationState, label: {})
                    } else {
                        Image(.arrowRight)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            })
            .background(.backgroundGray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        }
        
        private func handleAction(for item: SettingPath) {
            switch item {
            case .notification:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickPushAlarm())
                notificationState.toggle()
            case .petArchive:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickPetBox())
                coordinator.push(to: item)
            case .updateNickname:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickChangeName())
                coordinator.push(to: item)
            case .updateCalorie:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickChangeGoal())
                coordinator.push(to: item)
            default:
                coordinator.push(to: item)
            }
        }
    }
    
    struct SectionView: View {
        let items: [SettingPath]
        @Binding var showLogoutDialog: Bool
        let coordinator: AppCoordinator
        
        var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.backgroundGray)
                    .frame(height: 8)
                ForEach(items, id: \.self) { item in
                    WithPerceptionTracking {
                        Button(action: {
                            handleAction(for: item)
                        }) {
                            HStack {
                                Text(item.title)
                                    .font(.heading6_semibold16)
                                    .foregroundStyle(.textHeadlinePrimary)
                                Spacer()
                                Image(.arrowRight)
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 46)
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundBlack)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(.top, 16)
        }
        
        private func handleAction(for item: SettingPath) {
            switch item {
            case .logout:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickLogout())
                showLogoutDialog.toggle()
            case .updateTerms:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickTerms(touchPoint: "mypage"))
                coordinator.push(to: item)
            case .deleteUser:
                AnalyticsManager.shared.logEvent(event: SettingEvent.clickDeleteAccount())
                coordinator.push(to: item)
            case .inquiry:
                if let url = inquiryURL {
                    UIApplication.shared.open(url)
                }
            default:
                coordinator.push(to: item)
            }
        }

        private var inquiryURL: URL? {
            var components = URLComponents(string: "https://tally.so/r/Gx1GEe")
            components?.queryItems = [
                URLQueryItem(name: "userId", value: UserDefaultValue.userId),
                URLQueryItem(name: "deviceModel", value: deviceModel),
                URLQueryItem(name: "osVersion", value: UIDevice.current.systemVersion),
                URLQueryItem(name: "appVersion", value: appVersion)
            ]
            return components?.url
        }

        private var deviceModel: String {
            #if targetEnvironment(simulator)
            return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
                ?? UIDevice.current.model
            #else
            var systemInfo = utsname()
            uname(&systemInfo)

            return withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(cString: $0)
                }
            }
            #endif
        }

        private var appVersion: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                ?? "unknown"
        }
    }
}
#Preview {
    SettingView(coordinator: AppCoordinator(), store: Store(initialState: SettingViewReducer.State(), reducer: { SettingViewReducer(repository: SettingRepository()) }))
}
