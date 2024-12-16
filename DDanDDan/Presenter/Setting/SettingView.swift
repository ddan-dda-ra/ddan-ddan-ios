//
//  SettingView.swift
//  DDanDDan
//
//  Created by hwikang on 9/10/24.
//

import SwiftUI
import ComposableArchitecture

enum SettingPath: Hashable, CaseIterable {
    static var allCases: [SettingPath] {
        [.updateNickname, .updateCalorie, .updateTerms, .deleteUser, .logout]
    }
    
    static var topSection: [SettingPath] { [.updateNickname, updateCalorie] }
    static var bottomSection: [SettingPath] { [.updateTerms, .deleteUser, .logout] }
    
    case updateNickname
    case updateCalorie
//    case notification
    case updateTerms
    case deleteUser
    case deleteUserConfirm(reasons: Set<String>)
    case logout
    
    var description: String {
        switch self {
        case .updateNickname: "내 별명 수정"
        case .updateCalorie: "목표 칼로리 수정"
//        case .notification: "푸시 알림"
        case .updateTerms: "약관 및 개인정보 처리 동의"
        case .deleteUser: "탈퇴하기"
        case .logout: "로그아웃"
        default: ""
        }
    }
}

struct SettingView: View {
    @ObservedObject public var coordinator: AppCoordinator
    @State private var notificationState = true
    @State private var showLogoutDialog = false
    var appVersion: String {
        if let dictionary = Bundle.main.infoDictionary,
           let version = dictionary["CFBundleShortVersionString"] as? String {
            return version
        } else {
            return "버전 정보 없음"
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.backgroundGray.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 0) {
                CustomNavigationBar(
                    title: "설정",
                    leftButtonImage: Image(.arrow),
                    leftButtonAction: {
                        coordinator.pop()
                    }
                )
                VStack(spacing: 8) {
                    SectionView(items: SettingPath.topSection, notificationState: $notificationState, showLogoutDialog: $showLogoutDialog, coordinator: coordinator)
                    
                    SectionView(items: SettingPath.bottomSection, notificationState: $notificationState, showLogoutDialog: $showLogoutDialog, coordinator: coordinator)
                }
                Text("앱 버전 \(appVersion)")
                    .font(.body3_regular12)
                    .foregroundStyle(.iconGray)
                    .frame(height: 46)
                    .padding(.leading, 20)
            }
            .transparentFullScreenCover(isPresented: $showLogoutDialog) {
                DialogView(show: $showLogoutDialog, title: "정말 로그아웃 하시겠습니까?", description: "", rightButtonTitle: "로그아웃", leftButtonTitle: "취소") {
                    Task {
                        await UserManager.shared.logout()
                        coordinator.triggerHomeUpdate()
                        coordinator.setRoot(to: .login)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
}


struct SectionView: View {
    let items: [SettingPath]
    @Binding var notificationState: Bool
    @Binding var showLogoutDialog: Bool
    let coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button(action: {
                    handleAction(for: item)
                }) {
                    HStack {
                        Text(item.description)
                            .font(.heading6_semibold16)
                        Spacer()
//                        if item == .notification {
//                            Button {
//                                notificationState.toggle()
//                            } label: {
//                                Image(notificationState ? .toggleOn : .toggleOff)
//                            }
//                            .buttonStyle(.plain)
//                        } else {
                            Image(.arrowRight)
//                        }
                    }
                    .padding(.horizontal, 20)
//                    .padding(.vertical, 14)
                    .frame(height: 46)
                    .frame(maxWidth: .infinity)
                    .background(Color.backgroundBlack)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }
        }
        .navigationDestination(for: SettingPath.self) { path in
            switch path {
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
                DeleteUserView(coordinator: coordinator)
            case .deleteUserConfirm(let reasons):
                DeleteUserConfirmView(viewModel: DeleteUserViewModel(repository: SettingRepository()), coordinator: coordinator, selectedReason: reasons)
            case .logout:
                EmptyView()
            }
        }
    }
    
    private func handleAction(for item: SettingPath) {
        switch item {
//        case .notification:
//            // TODO: 푸시 알림 설정
//            break
        case .logout:
            showLogoutDialog.toggle()
        default:
            coordinator.push(to: item)
        }
    }
}

#Preview {
    SettingView(coordinator: AppCoordinator())
}
