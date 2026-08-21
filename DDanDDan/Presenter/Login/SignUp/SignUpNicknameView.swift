//
//  SignUpNicknameView.swift
//  DDanDDan
//
//  Created by hwikang on 8/20/24.
//

import SwiftUI

public struct SignUpNicknameView<ViewModel: SignUpViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var buttonDisabled: Bool = true
    @State private var nickname: String = ""
    @ObservedObject var coordinator: AppCoordinator
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    
                    Text("별명을 알려주세요")
                        .font(.neoDunggeunmo24)
                        .foregroundStyle(.white)
                        .padding(.top, 80)
                    
                    Text("별명")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.gray)
                        .padding(.top, 10)
                    TextField("별명을 입력해주세요", text: $nickname)
                        .padding()
                        .background(.backgroundGray)
                        .foregroundColor(.white)
                        .frame(height: 48)
                        .cornerRadius(8)
                        .border(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                if case let .failed(message) = viewModel.bootstrapState {
                    Text(message)
                        .font(.body2_regular14)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                GreenButton(action: {
                    AnalyticsManager.shared.logEvent(event: SignUpEvent.clickNextCTA)
                    Task {
                        if await viewModel.updateNickname(name: nickname) {
                            coordinator.push(to: .calorie)
                        }
                    }
                }, title: viewModel.bootstrapState == .loading ? "저장 중..." : "다음", disabled: buttonDisabled || viewModel.bootstrapState == .loading)
                .onChange(of: nickname) { newValue in
                    buttonDisabled = nickname.isEmpty
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SignUpNicknameView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: AppCoordinator())
}
