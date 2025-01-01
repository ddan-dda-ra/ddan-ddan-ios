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
                
                GreenButton(action: {
                    Task {
                        await viewModel.login()
                        coordinator.triggerHomeUpdate()
                        coordinator.setRoot(to: .home)
                    }
                }, title: "시작하기", disabled: false)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SignUpSuccessView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: AppCoordinator())
}
