//
//  UpdateNicknameView.swift
//  DDanDDan
//
//  Created by hwikang on 9/20/24.
//

import SwiftUI

struct UpdateNicknameView<ViewModel: UpdateNicknameViewModelProtocol>: View {
    @ObservedObject public var coordinator: AppCoordinator
    @ObservedObject var viewModel: ViewModel
    @State private var buttonDisabled: Bool = true
    
    var body: some View {
        ZStack {
            Color.backgroundBlack.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                CustomNavigationBar(
                    title: "내 별명 수정",
                    leftButtonImage: Image(.arrow),
                    leftButtonAction: {
                        coordinator.pop()
                    }
                )
                VStack(alignment: .leading) {
                    
                    Text("별명을 알려주세요")
                        .font(.neoDunggeunmo24)
                        .foregroundStyle(.white)
                        .padding(.top, 32)
                    
                    Text("별명")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.gray)
                        .padding(.top, 10)
                    TextField("별명을 입력해주세요", text: $viewModel.nickname)
                        .padding()
                        .background(.backgroundGray)
                        .foregroundColor(.white)
                        .frame(height: 48)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                GreenButton(action: {
                    Task {
                        if await viewModel.update() {
                            coordinator.pop()
                        }
                    }
                  
                }, title: "변경 완료", disabled: $buttonDisabled)
                .onChange(of: viewModel.nickname) { newValue in
                    buttonDisabled = viewModel.nickname.isEmpty
                }
            }
        }
        .navigationBarHidden(true)

    }
}

#Preview {
    UpdateNicknameView(coordinator: AppCoordinator(), viewModel: UpdateNicknameViewModel(nickname: "", repository: SettingRepository()))
}
