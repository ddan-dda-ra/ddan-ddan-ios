//
//  PetArchiveView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI

struct PetArchiveView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject var viewModel: PetArchiveViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
                .ignoresSafeArea()
            
            VStack {
                CustomNavigationBar(
                    title: "펫 보관함",leftButtonImage: Image(.arrow), leftButtonAction: {
                        coordinator.pop()
                    },
                    buttonSize: 24
                )
                .padding(.bottom, 28)
                HStack {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<9, id: \.self) { index in
                            ZStack {
                                let pet = viewModel.petList[safe: index]
                                
                                // UserDefaults에서 저장된 petId와 비교하여 border 색상 설정
                                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                                    .stroke(viewModel.selectedIndex == index ? Color.buttonGreen : Color.clear, lineWidth: 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8).foregroundColor(.borderGray)
                                    )
                                    .frame(maxWidth: 100, maxHeight: 100)
                                
                                if let pet = pet {
                                    pet.type.image(for: pet.level)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 100, maxHeight: 100)
                                } else {
                                    Image(.questionMark)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .padding(24)
                                }
                            }
                            .onTapGesture {
                                viewModel.toggleSelection(for: index)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                Spacer()
                GreenButton(action: {
                    if !viewModel.petId.isEmpty {
                        Task {
                            await viewModel.selectMainPet(id: viewModel.petId)
                            
                        }
                    } else {
                        viewModel.showToastMessage()
                    }
                }, title: "선택 완료", disabled: false)
                .padding(.bottom, 44)
            }
            if viewModel.showToast {
                VStack {
                    ToastView(message: "새로운 펫을 준비중이에요")
                        .onTapGesture {
                            viewModel.hideToastMessage()
                        }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity)) // 사라질 때는 페이드 아웃만
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: viewModel.showToast)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 250)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.fetchPetArchive()
            }
        }
        .onChange(of: viewModel.isSelectedMainPet) { newValue in
            if newValue {
                coordinator.triggerHomeUpdate()
                coordinator.pop()
            }
        }
    }
}


#Preview {
    PetArchiveView(coordinator: AppCoordinator(), viewModel: PetArchiveViewModel(repository: HomeRepository()))
}
