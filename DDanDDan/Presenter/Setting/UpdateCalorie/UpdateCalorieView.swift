//
//  UpdateCalorieView.swift
//  DDanDDan
//
//  Created by hwikang on 9/26/24.
//

import SwiftUI

struct UpdateCalorieView: View {
    @ObservedObject var viewModel: UpdateCalorieViewModel
    @State private var buttonDisabled: Bool = true
    @ObservedObject public var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Color.backgroundBlack.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                CustomNavigationBar(
                    title: "목표 칼로리 수정",
                    leftButtonImage: Image(.arrow),
                    leftButtonAction: {
                        coordinator.pop()
                    }
                )
                Text("하루 목표 칼로리를\n설정해 주세요")
                    .font(.neoDunggeunmo24)
                    .lineSpacing(8)
                    .foregroundStyle(.white)
                    .padding(.top, 32)
                    .padding(.horizontal, 20)
                HStack(alignment: .center) {
                    Button {
                        viewModel.decreaseCalorie()
                    } label: {
                        Image("minusButtonRounded")
                    }
                    Text(String(viewModel.calorie))
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.buttonGreen)
                        .frame(width: 84, height: 80)
                        .background(.backgroundGray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button {
                        viewModel.increaseCalorie()
                    } label: {
                        Image("plusButtonRounded")
                    }
                }.frame(maxWidth: .infinity)
                    .padding(.top, 56)
                
                Spacer()
                
                GreenButton(action: {
                    Task {
                        if await viewModel.update() {
                            coordinator.triggerHomeUpdate()
                            coordinator.pop()
                        }
                    }
                            
                }, title: "변경 완료", disabled: .constant(false))
            }
            TransparentOverlayView(isPresented: viewModel.showToast, isDimView: false) {
                VStack {
                    ToastView(message: viewModel.toastMessage)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: viewModel.showToast)
                .position(x: UIScreen.main.bounds.width / 2 + 10, y: UIScreen.main.bounds.height - 250)
            }

        }
        .navigationBarHidden(true)
    }

}

#Preview {
    UpdateCalorieView(viewModel: UpdateCalorieViewModel(repository: SettingRepository()), coordinator: AppCoordinator())
}
