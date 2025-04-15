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
        [.petArchive, .updateNickname, .updateCalorie, .notification, .updateTerms, .deleteUser, .logout]
    }
    
    static var myInfoSection: [SettingPath] { [.petArchive, .updateNickname, updateCalorie] }
    static var notificationSection: [SettingPath] { [.notification] }
    static var bottomSection: [SettingPath] { [.updateTerms, .deleteUser, .logout] }
    
    case petArchive
    case updateNickname
    case updateCalorie
    case notification
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
                VStack(alignment: .leading, spacing: 0) {
                    CustomNavigationBar(
                        title: "마이 페이지",
                        leftButtonImage: Image(.arrow),
                        leftButtonAction: {
                            coordinator.pop()
                        }
                    )
                    
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
                        .padding(.leading, 20)
                }
                .transparentFullScreenCover(isPresented: logoutDialogBinding) {
                    
                    DialogView(show: logoutDialogBinding,
                               title: "정말 로그아웃 하시겠습니까?", description: "", rightButtonTitle: "로그아웃", leftButtonTitle: "취소") {
                        Task {
                            await UserManager.shared.logout()
                            coordinator.triggerHomeUpdate()
                            coordinator.setRoot(to: .login)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
                notificationState.toggle()
                break
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
                showLogoutDialog.toggle()
            default:
                coordinator.push(to: item)
            }
        }
    }
}
#Preview {
    SettingView(coordinator: AppCoordinator(), store: Store(initialState: SettingViewReducer.State(), reducer: { SettingViewReducer(repository: SettingRepository()) }))
}

