//
//  SignUpEggView.swift
//  DDanDDan
//
//  Created by hwikang on 8/17/24.
//

import SwiftUI

public struct SignUpEggView<ViewModel: SignUpViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var buttonDisabled: Bool = true
    @State private var selectedEgg: PetType? = nil
    @ObservedObject var coordinator: AppCoordinator
  
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                
                Text("마음에 드는\n알을 선택해 주세요")
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.white)
                    .padding(.top, 80)
                    .padding(.horizontal, 20)
                HStack(alignment: .center) {
                    Spacer()
                    eggGrid
                    Spacer()
                }
                
                Spacer()
                
                GreenButton(action: {
                    guard let selectedEgg = selectedEgg else { return }
                    Task {
                        if await viewModel.updatePet(petType: selectedEgg) {
                            coordinator.push(to: .success)
                        }
                    }
                  
                }, title: "다음", disabled: buttonDisabled)
                .onChange(of: selectedEgg) { newValue in
                    buttonDisabled = selectedEgg == nil
                }
                
            }
        }
        .navigationBarHidden(true)
    }
    
    var eggGrid: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                EggItem(selectedEgg: $selectedEgg, imageName: "eggPink", type: .pinkCat)
                EggItem(selectedEgg: $selectedEgg, imageName: "eggOrange", type: .greenHam)
                
            }
            HStack(spacing: 30) {
                EggItem(selectedEgg: $selectedEgg, imageName: "eggPurple", type: .purpleDog)
                EggItem(selectedEgg: $selectedEgg, imageName: "eggBlue", type: .bluePenguin)
                
            }
        }.padding(.top, 75)
    }
}

struct EggItem: View {
    @Binding var selectedEgg: PetType?
    public let imageName: String, type: PetType
    
    var body: some View {
        Image(imageName)
            .onTapGesture {
                selectedEgg = type
            }
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(red: 19/255, green: 230/255, blue: 149/255),
                              lineWidth: selectedEgg == type ? 3 : 0))
    }
}

#Preview {
    SignUpEggView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: AppCoordinator())
}
