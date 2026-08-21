//
//  SignUpSuccessView.swift
//  DDanDDan
//
//  Created by hwikang on 8/26/24.
//

import SwiftUI

import Lottie

struct SignUpSuccessView<ViewModel: SignUpViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                Text("딴딴에 가입하신 것을\n환영해요!")
                    .font(.neoDunggeunmo24)
                    .lineSpacing(8)
                    .foregroundStyle(.white)
                    .padding(.top, 80)
                    .padding(.horizontal, 20)
                HStack(alignment: .center) {
                    LottieView(animation: .named(LottieString.confetti))
                        .playing(loopMode: .playOnce)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 64)
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
                    AnalyticsManager.shared.logEvent(event: SignUpEvent.clickCTA(touchpoint: "sign-up-start"))
                    Task {
                        guard await viewModel.login() else { return }
                        guard let userInfo = viewModel.preparedUserInfo,
                              let mainPet = viewModel.preparedMainPet else { return }
                        coordinator.commitAuthenticatedBootstrap(userInfo: userInfo, petInfo: mainPet)
                    }
                }, title: viewModel.bootstrapState == .loading ? "준비 중..." : "시작하기", disabled: viewModel.bootstrapState == .loading)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SignUpSuccessView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: AppCoordinator())
}
