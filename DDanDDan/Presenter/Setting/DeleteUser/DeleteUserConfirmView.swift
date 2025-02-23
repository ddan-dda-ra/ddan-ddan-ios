//
//  DeleteUserConfirmView.swift
//  DDanDDan
//
//  Created by hwikang on 10/14/24.
//

import SwiftUI
import ComposableArchitecture

struct DeleteUserConfirmView: View {
    @ObservedObject public var coordinator: AppCoordinator
    let store: StoreOf<DeleteUserReducer>
    
    var body: some View {
        WithViewStore(store) { $0 } content: { viewStore in
            
            ZStack {
                Color.backgroundBlack.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    CustomNavigationBar(
                        title: "",
                        leftButtonImage: Image(.arrow),
                        leftButtonAction: {
                            coordinator.pop()
                        }
                    )
                    Text(viewStore.name + "님\n탈퇴하기 전 확인해 주세요")
                        .font(.neoDunggeunmo24)
                        .lineSpacing(8)
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    Text("딴딴에서 함께했던 펫들과 운동기록을\n다시 볼 수 없어요.")
                        .font(.body1_regular16)
                        .lineSpacing(8)
                        .foregroundStyle(.iconGray)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                    
                    Image("deleteUser").frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    CheckButton(isChecked: viewStore.isButtonChecked, title: "모두 다 꼼꼼히 확인했어요") {
                        viewStore.send(.checkButton)
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                    GreenButton(action: {
                        viewStore.send(.deleteUser)
                        
                    }, title: "탈퇴하기", disabled: !viewStore.isButtonChecked)
                }
            }
            .onChange(of: viewStore.deleteFinished) { deleteFinished in
                if deleteFinished {
                    coordinator.setRoot(to: .login)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
}

#Preview {
    DeleteUserConfirmView(coordinator: AppCoordinator(), store: Store(initialState: DeleteUserReducer.State(), reducer: { DeleteUserReducer(repository: SettingRepository()) }))
}
