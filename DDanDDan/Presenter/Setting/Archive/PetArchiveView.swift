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
            
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "펫 보관함",
                    leftButtonImage: Image(.arrow),
                    leftButtonAction: {
                        coordinator.pop()
                    }
                )
                .padding(.bottom, 28)
                ScrollView {
                    petVGrid
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
                }, title: viewModel.isButtonDisable ? "선택 완료" : "선택 하기", disabled: viewModel.isButtonDisable)
            }
            TransparentOverlayView(isPresented: viewModel.showToast, isDimView: false) {
                VStack {
                    ToastView(message: viewModel.toastMessage, toastType: .info)
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 180.adjustedHeight)
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
                coordinator.triggerHomeUpdate(trigger: true)
                coordinator.pop()
            }
        }
    }
    
    var petVGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(0..<viewModel.gridItemCount, id: \.self) { index in
                ZStack {
                    let pet = viewModel.petList[safe: index]
                    RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                        .strokeBorder(viewModel.selectedIndex == index ? Color.buttonGreen : Color.clear, lineWidth: 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8).foregroundColor(.borderGray)
                        )
                        .frame(width: 100, height: 100)
                        
                    
                    if let pet = pet {
                        Image(pet.type.image(for: pet.level))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 80, maxHeight: 80)
                    } else {
                        Image(.questionMark)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .padding(24)
                    }
                }
                .onTapGesture {
                    if viewModel.petList[safe: index] == nil {
                        viewModel.showToastMessage()
                    } else {
                        viewModel.toggleSelection(for: index)
                    }
                }
            }
        }
    }
}


#Preview {
    PetArchiveView(coordinator: AppCoordinator(), viewModel: PetArchiveViewModel(repository: HomeRepository()))
}
