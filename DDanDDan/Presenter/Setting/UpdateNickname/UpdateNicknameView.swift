//
//  UpdateNicknameView.swift
//  DDanDDan
//
//  Created by hwikang on 9/20/24.
//

import SwiftUI
import ComposableArchitecture

struct UpdateNicknameView: View {
    @ObservedObject public var coordinator: AppCoordinator
    let store: StoreOf<UpdateNicknameReducer>
    
    var body: some View {
        WithViewStore(store) { $0 } content: { viewStore in
            ZStack {
                Color.backgroundBlack.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    CustomNavigationBar(
                        title: "내 별명 수정",
                        leftButtonImage: Image(.arrow),
                        leftButtonAction: {
                            coordinator.pop()
                        },
                        buttonSize: 24
                    )
                    VStack(alignment: .leading) {
                        
                        Text("별명을 알려주세요")
                            .font(.neoDunggeunmo24)
                            .foregroundStyle(.white)
                            .padding(.top, 32)
                        
                        Text("별명")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray)
                            .padding(.top, 10)
                        TextField("별명을 입력해주세요", text: viewStore.binding(get: { $0.nickName}, send: UpdateNicknameReducer.Action.inputNickname))
                            .padding()
                            .background(.backgroundGray)
                            .foregroundColor(.white)
                            .frame(height: 48)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    GreenButton(action: {
                        viewStore.send(.requestUpdate)
                    }, title: "변경 완료", disabled: viewStore.buttonDisabled)
                    .onChange(of: viewStore.calorieUpdated) { updateSuccess in
                        coordinator.pop()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    UpdateNicknameView(coordinator: AppCoordinator(),
                       store: Store(initialState: UpdateNicknameReducer.State(),
                                    reducer: { UpdateNicknameReducer(repository: SettingRepository())}))
}
