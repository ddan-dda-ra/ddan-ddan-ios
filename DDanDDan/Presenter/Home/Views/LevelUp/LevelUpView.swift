//
//  SuccessView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI

struct LevelUpView: View {
    @ObservedObject var coordinator: AppCoordinator
    private let level: Int
    private let petType: PetType
    
    init(coordinator: AppCoordinator, level: Int, petType: PetType) {
        self.coordinator = coordinator
        self.level = level
        self.petType = petType
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(.backgroundBlack).ignoresSafeArea()
            VStack {
                Spacer()
                imageView
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                Text(level == 5 ? "펫 성장 완료!" : "lv.\(level)로\n업그레이드 되었어요!")
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                    .padding(.top, 32)
                if level == 5 {
                    Text("성장을 완료한 펫과 꾸준히 운동해서\n경험치를 올려보세요")
                        .multilineTextAlignment(.center)
                        .font(.body3_regular12)
                        .foregroundStyle(.iconGray)
                        .lineSpacing(8)
                        .padding(.top, 8)
                }
                Spacer()
                GreenButton(action: {
                    coordinator.pop()
                }, title: "성장하기", disabled: false)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    var imageView: some View {
        ZStack {
            Image(.pangGraphics)
            Image(petType.image(for: level))
                .resizable()
                .frame(width: 96, height: 96)
                .aspectRatio(contentMode: .fill)
        }
    }
}

#Preview {
    LevelUpView(coordinator: .init(), level: 4, petType: .bluePenguin)
}
