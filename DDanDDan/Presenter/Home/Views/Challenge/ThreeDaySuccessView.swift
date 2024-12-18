//
//  LevelUpView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI

struct ThreeDaySuccessView: View {
    @ObservedObject var coordinator: AppCoordinator
    var totalKcal: Int
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(.backgroundBlack)
            VStack {
                Text("3일 내내 운동을\n열심히 하셨네요!")
                    .multilineTextAlignment(.center)
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                    .padding(.top, 124)
                    .padding(.bottom, 80)
                
                VStack(spacing: 16) {
                    listComponentView(
                        image: Image(.kcalGraphic),
                        title: "3일간 소모한 칼로리",
                        content: "\(totalKcal)kcal"
                    )
                    listComponentView(
                        image: Image(.luckyGraphic),
                        title: "받은 장난감",
                        content: "행운의 풀떼기 1개"
                    )
                }
                .padding(.horizontal, 20)
                Spacer()
                GreenButton(action: {
                    coordinator.pop()
                }, title: "획득하기", disabled: false)
                .padding(.bottom, 44)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    /// 리스트 컴포넌트 뷰
    func listComponentView(image: Image, title: String, content: String) -> some View {
        ZStack(alignment: .leading) {
            Color(.borderGray)
                .cornerRadius(8)
            HStack {
                image
                    .resizable()
                    .frame(width: 56, height: 56)
                    .padding(.trailing, 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.heading5_semibold18)
                        .foregroundStyle(.textHeadlinePrimary)
                    Text("\(content)")
                        .font(.subTitle1_semibold14)
                        .foregroundStyle(.textBodyTeritary)
                }
            }
            .padding(.all,12)
        }
        .frame(height: 80)
    }
}

#Preview {
    ThreeDaySuccessView(coordinator: .init(), totalKcal: 0)
}
