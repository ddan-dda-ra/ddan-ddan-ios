//
//  DeleteUserView.swift
//  DDanDDan
//
//  Created by hwikang on 10/7/24.
//

import SwiftUI
import ComposableArchitecture

struct DeleteUserView: View {
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
                    Text("탈퇴하는 이유가\n무엇인가요?")
                        .font(.neoDunggeunmo24)
                        .lineSpacing(8)
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20))
                    List(viewStore.reasons, id: \.self) { reason in
                        DeleteUserReasonButton(title: reason, isSelected: viewStore.selectedReason.contains(reason)) {
                            viewStore.send(.selectReason(reason))
                        }
                        .foregroundStyle(.white)
                        .listRowBackground(Color.backgroundBlack)
                        .listRowSeparator(.hidden)
                    }
                    .listRowSpacing(4)
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    Spacer()
                    GreenButton(action: {
                        coordinator.push(to: .deleteUserConfirm(store: store))
                    }, title: "탈퇴하기", disabled: viewStore.selectedReason.isEmpty)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
}

struct DeleteUserReasonButton: View {
    
    private let title: String, isSelected: Bool
    private let action: () -> Void
    init(title: String, isSelected: Bool,
         action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    var body: some View {
        
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.body1_regular16)
                Spacer()
                Image(isSelected ? "checkboxCircleSelected" :"checkboxCircle")
            }
        }
    }
}

#Preview {
    DeleteUserView(coordinator: AppCoordinator(), store: Store(initialState: DeleteUserReducer.State(), reducer: { DeleteUserReducer(repository: SettingRepository()) }))
}
