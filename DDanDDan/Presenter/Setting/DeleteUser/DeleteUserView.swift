//
//  DeleteUserView.swift
//  DDanDDan
//
//  Created by hwikang on 10/7/24.
//

import SwiftUI

struct DeleteUserView: View {
    @ObservedObject public var coordinator: AppCoordinator
    
    @State var selectedReason: Set<String> = []
    private let reasons: [String] = [
        "쓰지 않는 앱이에요", "오류가 생겨서 쓸 수 없어요", "개인정보가 불안해요", "앱 사용법을 모르겠어요", "기타"
    ]
    
    var body: some View {
        
        ZStack {
            Color.backgroundBlack.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                CustomNavigationBar(
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
                List(reasons, id: \.self) { reason in
                    DeleteUserReasonButton(title: reason, isSelected: selectedReason.contains(reason)) {
                        addReason(reason: reason)
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
                    coordinator.push(to: .deleteUserConfirm(reasons: selectedReason))
                }, title: "탈퇴하기", disabled: .constant(selectedReason.isEmpty))
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func addReason(reason: String) {
        if selectedReason.contains(reason) {
            selectedReason.remove(reason)
        } else {
            selectedReason.insert(reason)
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
    DeleteUserView(coordinator: AppCoordinator())
}
