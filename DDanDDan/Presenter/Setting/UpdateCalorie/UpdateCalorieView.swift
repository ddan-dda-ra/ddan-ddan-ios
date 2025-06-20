//
//  UpdateCalorieView.swift
//  DDanDDan
//
//  Created by hwikang on 9/26/24.
//

import SwiftUI
import ComposableArchitecture

struct UpdateCalorieView: View {
    @ObservedObject public var coordinator: AppCoordinator
    let store: StoreOf<UpdateCalorieReducer>

    var body: some View {
        WithViewStore(store) { $0 } content: { viewStore in
            
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
                            viewStore.send(.decreaseCalorie)
                        } label: {
                            Image("minusButtonRounded")
                        }
                        Text(String(viewStore.calorie))
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.buttonGreen)
                            .frame(width: 84, height: 80)
                            .background(.backgroundGray)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button {
                            viewStore.send(.increaseCalorie)
                        } label: {
                            Image("plusButtonRounded")
                        }
                    }.frame(maxWidth: .infinity)
                        .padding(.top, 56)
                    
                    Spacer()
                    
                    GreenButton(action: {
                        viewStore.send(.requestUpdate)
                    }, title: "변경 완료", disabled: false)
                }
                TransparentOverlayView(isPresented: !viewStore.toastMessage.isEmpty, isDimView: false) {
                    VStack {
                        ToastView(message: viewStore.toastMessage, toastType: .info)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: viewStore.toastMessage)
                    .position(x: UIScreen.main.bounds.width / 2 + 10, y: UIScreen.main.bounds.height - 250)
                }
                .onChange(of: viewStore.calorieUpdated) { value in
                    Task {
                        try await Task.sleep(for: .milliseconds(3000))
                        if value { coordinator.triggerHomeUpdate(trigger: true) }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    UpdateCalorieView(coordinator: AppCoordinator(),
                      store: Store(initialState: UpdateCalorieReducer.State(), reducer: { UpdateCalorieReducer(repository: SettingRepository()) }))
}
