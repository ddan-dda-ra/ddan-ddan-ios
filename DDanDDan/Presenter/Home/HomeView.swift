//
//  HomeView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI
import HealthKit
import ComposableArchitecture
import Lottie

enum HomePath: Hashable {
    case successThreeDay(totalKcal: Int)
    case newPet
    case upgradePet(level: Int, petType: PetType)
}

struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject var viewModel: HomeViewModel
    private let rankStore = Store(initialState: RankViewReducer.State()) {
        RankViewReducer()
    }
    
    private let isSEDevice = UIScreen.isSESizeDevice
    
    var body: some View {
        ZStack {
                Color(.backgroundBlack)
                    .ignoresSafeArea(edges: [.vertical])
                VStack(alignment: .center) {
                    kcalView
                        .padding(.top, 32)
                        .padding(.bottom, isSEDevice ? 24 : 14.adjusted)
                    petBackgroundView
                        .padding(.bottom, isSEDevice ? 15 : 20.adjusted)
                        .padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
                    levelView
                        .padding(.bottom, 12.adjusted)
                        .padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
                    actionButtonView
                        .padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
                }
                .padding(.top, isSEDevice ? 16 : 40.adjustedHeight)
                .padding(.bottom, isSEDevice ? 24 : 80.adjustedHeight)
                .frame(maxWidth: 375.adjustedWidth, maxHeight: 810.adjustedHeight)
                TransparentOverlayView(isPresented: viewModel.showToast, isDimView: false) {
                    VStack {
                        ToastView(message: viewModel.toastMessage, toastType: .info)
                    }
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 230.adjustedHeight)
                }
                TransparentOverlayView(isPresented: viewModel.isPresentEarnFood) {
                    ImageDialogView(
                        show: $viewModel.isPresentEarnFood,
                        image: .eatGraphic,
                        title: "먹이를 얻었어요!",
                        description: "사과 \(viewModel.earnFood)개",
                        buttonTitle: "획득하기"
                    ) {
                        viewModel.showRandomBubble(type: .success)
                    }
                }
                .onChange(of: viewModel.isLevelUp) { newLevel in
                    if newLevel {
                        coordinator.push( to: .upgradePet(
                            level: viewModel.homePetModel.level,
                            petType: viewModel.homePetModel.petType
                        )
                        )
                        viewModel.isLevelUp = false
                    }
                }
                .onChange(of: viewModel.isMaxLevel) { newValue in
                    if newValue {
                        coordinator.push( to: .newPet)
                        viewModel.isMaxLevel = false
                    }
                }
                .onChange(of: viewModel.isGoalMet) { newValue in
                    if newValue {
                        coordinator.push( to: .successThreeDay(totalKcal: viewModel.threeDaysTotalKcal))
                        viewModel.isGoalMet = false
                    }
                }
                .onReceive(coordinator.$shouldUpdateHomeView) { shouldUpdate in
                    if shouldUpdate {
                        Task {
                            await viewModel.fetchHomeInfo()
                            
                            coordinator.triggerHomeUpdate(trigger: false)
                        }
                    }
                }
                
            }
            .navigationBarBackButtonHidden()
    }
}

extension HomeView {
    
    var kcalView: some View {
        HStack(alignment: .lastTextBaseline,spacing: 4) {
            Text("\(viewModel.currentKcal)")
                .font(.neoDunggeunmo52)
                .foregroundStyle(.textHeadlinePrimary)
            Text("/")
                .font(.neoDunggeunmo42)
                .foregroundStyle(.textHeadlinePrimary)
            Text("\(viewModel.homePetModel.goalKcal) kcal")
                .font(.neoDunggeunmo22)
                .foregroundStyle(.textHeadlinePrimary)
        }
        .frame(height: 52.adjusted)
    }
    
    var petBackgroundView: some View {
        ZStack {
            if isSEDevice {
                viewModel.homePetModel.petType.seBackgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                viewModel.homePetModel.petType.backgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 370.adjusted)
            }
            VStack {
                Image(viewModel.bubbleImage)
                    .opacity(viewModel.showBubble ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.1), value: viewModel.showBubble)
                    .transition(.opacity)
                    .frame(minWidth: 75, maxWidth: 167, minHeight: 56)
                    .offset(y: viewModel.showBubble ? (viewModel.homePetModel.level > 3 ? 5 : 10.adjustedHeight) : 25)
                petImage
                    .onTapGesture {
                        viewModel.showRandomBubble(type: .normal)
                    }
            }
            .offset(y: isSEDevice ? 30.adjusted : 55.adjustedHeight)
        }
    }
    
    var petImage: some View {
        Group {
            if viewModel.isPlayingSpecialAnimation {
                LottieView(animation: .named(viewModel.currentLottieAnimation))
                    .playing(loopMode: .loop)
                    .frame(width: 100.adjusted, height: 100.adjusted)
            } else {
                LottieView(animation: .named(viewModel.homePetModel.petType.lottieString(level: viewModel.homePetModel.level)))
                    .playing(loopMode: .loop)
                    .frame(width: 100.adjusted, height: 100.adjusted)
            }
        }
    }
    
    var levelView: some View {
        VStack {
            HStack {
                Text("LV.\(viewModel.homePetModel.level)")
                    .font(.neoDunggeunmo14)
                    .padding(.vertical, 4.adjusted)
                    .padding(.horizontal, 6.adjustedWidth)
                    .foregroundStyle(.white)
                    .background(.borderGray)
                    .cornerRadius(4)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.homePetModel.exp))
                    .font(.neoDunggeunmo16)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            ZStack(alignment: .leading) {
                Image(.gaugeBackground)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 28)
                // expCount 계산
                let expCount = min(Int(viewModel.homePetModel.exp) / 4, (viewModel.homePetModel.exp == 100 ? 25 : 25 - 1))
                
                // Rectangle 생성
                HStack(spacing: 4) {
                    ForEach(0..<25, id: \.self) { index in
                        if index < expCount {
                            Rectangle()
                                .fill(viewModel.homePetModel.petType.color)
                                .frame(width: 8.adjusted, height: 12)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 8.adjusted, height: 12)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
    
    var actionButtonView: some View {
        HStack(spacing: 12.adjusted) {
            HomeButton(buttonTitle: "먹이주기", count: viewModel.homePetModel.feedCount, image: .iconFeed)
                .onTapGesture {
                    viewModel.feedPet()
                }
            HomeButton(buttonTitle: "놀아주기", count: viewModel.homePetModel.toyCount, image: .iconToy)
                .onTapGesture {
                    viewModel.playWithPet()
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 95)
    }
}

#Preview {
    HomeView(coordinator: .init(), viewModel: HomeViewModel(repository: HomeRepository()))
}
