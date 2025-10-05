//
//  FirendAddView.swift
//  DDanDDan
//
//  Created by 이지희 on 10/5/25.
//

import SwiftUI

struct FriendAddView: View {
    @ObservedObject var coordinator: AppCoordinator
    private let level: Int
    private let petType: PetType
    
    init(
        coordinator: AppCoordinator,
        level: Int,
        petType: PetType
    ) {
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
                Text("친구가 되었어요!")
                    .lineSpacing(8)
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                    .padding(.top, 32)
                Text("이제 친구와 함께 운동해보세요!")
                    .font(.body1_regular16)
                    .foregroundStyle(.iconGray)
                    .lineSpacing(8)
                    .padding(.top, 8)
                Spacer()
                GreenButton(action: {
                    coordinator.pop()
                }, title: "확인", disabled: false)
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
    FriendAddView(coordinator: .init(), level: 2, petType: .bluePenguin)
}
