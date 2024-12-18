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
            Color(.backgroundBlack)
            VStack {
                Spacer()
                imageView
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                Text("lv.\(level)로\n업그레이드 되었어요!")
                    .multilineTextAlignment(.center)
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                    .padding(.vertical, 32)
                Spacer()
                GreenButton(action: {
                    coordinator.pop()
                }, title: "성장하기", disabled: false)
                .padding(.bottom, 44)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    var imageView: some View {
        ZStack {
            Image(.pangGraphics)
            petType.image(for: level)
                .resizable()
                .frame(width: 96, height: 96)
                .aspectRatio(contentMode: .fill)
        }
    }
}

#Preview {
    LevelUpView(coordinator: .init(), level: 4, petType: .bluePenguin)
}
