//
//  DeleteUserConfirmView.swift
//  DDanDDan
//
//  Created by hwikang on 10/14/24.
//

import SwiftUI

struct DeleteUserConfirmView: View {
    @ObservedObject var viewModel: DeleteUserViewModel
    @ObservedObject public var coordinator: AppCoordinator
    public let selectedReason: Set<String>
    
    @State var isChecked: Bool = false
    
    var body: some View {
        ZStack {
            Color.backgroundBlack.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                CustomNavigationBar(
                    leftButtonImage: Image(.arrow),
                    leftButtonAction: {
                        coordinator.pop()
                    }
                )
                Text(viewModel.name + "님\n탈퇴하기 전 확인해 주세요")
                    .font(.neoDunggeunmo24)
                    .lineSpacing(8)
                    .foregroundStyle(.white)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                Text("딴딴에서 함께했던 펫들과 운동기록을\n다시 볼 수 없어요.")
                    .font(.body1_regular16)
                    .lineSpacing(8)
                    .foregroundStyle(.iconGray)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                Image("deleteUser").frame(maxWidth: .infinity, alignment: .center)
                Spacer()
                CheckButton(isChecked: isChecked, title: "모두 다 꼼꼼히 확인했어요") {
                    isChecked.toggle()
                }
                .padding(.leading, 20)
                .padding(.bottom, 20)
                GreenButton(action: {
                    Task {
                        _ = await viewModel.deleteUser(reasons: selectedReason)
                        coordinator.setRoot(to: .login)
                        
                    }
                }, title: "탈퇴하기", disabled: Binding(get: { !isChecked }, set: {_ in}))
            }
        }
        .navigationBarHidden(true)
    }
    
}

#Preview {
    DeleteUserConfirmView(viewModel: DeleteUserViewModel(repository: SettingRepository()), coordinator: AppCoordinator(), selectedReason: [])
}
