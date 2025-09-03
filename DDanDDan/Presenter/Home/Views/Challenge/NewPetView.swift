//
//  NewPetView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/20/24.
//

import SwiftUI

import Lottie

struct NewPetView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(.backgroundBlack)
                .ignoresSafeArea()
            VStack {
                Spacer()
                LottieView(animation: .named(LottieString.confetti))
                    .playing(loopMode: .playOnce)
                Text("이제 새로운 펫을\n뽑을 수 있어요!")
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                Spacer()
                GreenButton(action: {
                    coordinator.popToRoot()
                }, title: "확인", disabled: false)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NewPetView(coordinator: .init())
}
