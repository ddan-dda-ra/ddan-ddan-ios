//
//  RandomGachaPetView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/4/25.
//

import SwiftUI

import Lottie

struct RandomGachaPetView: View {
    
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 180
    @State private var showShadow: Bool = false
    @State private var showTexts: Bool = false
    
    @StateObject var viewModel: RandomGachaPetViewModel
    
    var selectPet: Bool = false
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
                .opacity(0.8)
                .ignoresSafeArea()
            
            VStack {
                petCardView
                    .frame(width: 160, height: 160)
                    .shadow(color: .white.opacity(showShadow ? 0.4 : 0), radius: 72)
                    .padding(32)
                    .scaleEffect(scale)
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.easeOut(duration: 0.4), value: scale)
                    .animation(.easeInOut(duration: 0.8), value: rotation)
                if showTexts {
                    VStack {
                        Text(viewModel.isSelectedRandomPet ? "반가워!" : "어떤 펫이 나올까요?")
                            .font(.neoDunggeunmo24)
                            .foregroundStyle(Color.textHeadlinePrimary)
                            .padding(.bottom, 8)
                        Text(viewModel.isSelectedRandomPet ? "새로운 펫을 뽑았어요!" : "아래 버튼을 눌러 알을 골라주세요")
                            .font(.body1_regular16)
                            .foregroundStyle(.textBodyTeritary)
                            .padding(.bottom, 32)
                        if viewModel.isSelectedRandomPet {
                            HStack {
                                Button("닫기") {
                                    viewModel.tapDisMissButton()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .padding(.trailing, 8)
                                
                                Button("키우기") {
                                    viewModel.tapGrowupButton()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        } else {
                            Button("선택하기") {
                                viewModel.tapSelectButton()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
//                    .opacity(showTexts ? 1 : 0)
                    .offset(y: showTexts ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(0.6), value: showTexts)
                }
            }
        }
        .onAppear {
            withAnimation {
                scale = 1.0
                rotation = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showShadow = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    showTexts = true
                }
            }
        }
    }
    
    
    var petCardView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.borderGray, lineWidth: 4)
                )
            LottieView(animation: .named(LottieString.randomEgg))
                .playing(loopMode: .loop)
                .frame(width: 136, height: 136)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

}

#Preview {
    RandomGachaPetView(viewModel: .init(homeRepository: HomeRepository()))
}
