//
//  NewPetView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/20/24.
//

import SwiftUI

struct NewPetView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject var viewModel: NewPetViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(.backgroundBlack)
            VStack {
                Spacer()
                imageView
                Text("새로운 펫을\n키울 수 있어요!")
                    .multilineTextAlignment(.center)
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                    .padding(.vertical, 32)
                Spacer()
                GreenButton(action: {
                    Task {
                        await viewModel.createRandomPet()
                    }
                }, title: "시작하기", disabled: false)
                .padding(.bottom, 44)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    var imageView: some View {
        ZStack {
            Image(.pangGraphics)
            Image(.pinkEgg)
                .offset(y: 18)
        }
    }
}

#Preview {
    NewPetView(coordinator: .init(), viewModel: .init(homeRepository: HomeRepository(), coordinator: .init()))
}
