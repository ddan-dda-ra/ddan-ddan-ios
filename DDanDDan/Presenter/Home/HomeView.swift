//
//  HomeView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI
import HealthKit

import Lottie

enum HomePath: Hashable {
    case setting
    case petArchive
    case successThreeDay(totalKcal: Int)
    case newPet
    case upgradePet(level: Int, petType: PetType)
}

struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject var viewModel: HomeViewModel
    
    private let isSEDevice = UIScreen.isSESizeDevice
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
                .ignoresSafeArea(edges: [.vertical])
            VStack(alignment: .center) {
                CustomNavigationBar(
                    title: "",
                    leftButtonImage: Image(.iconDocs),
                    leftButtonAction: {
                        coordinator.push(to: .petArchive)
                    },
                    rightButtonImage: Image(.iconSetting),
                    rightButtonAction: {
                        coordinator.push(to: .setting)
                    },
                    buttonSize: 28
                )
                kcalView
                    .padding(.bottom, isSEDevice ? 24 : 14.adjusted)
                petBackgroundView
                    .padding(.bottom, isSEDevice ? 15 : 28.adjusted)
                
                    .padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
                levelView
                    .padding(.bottom, 20.adjusted)
                    .padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
                actionButtonView
                    .padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
            }
            .padding(.top, isSEDevice ? 16 : 40.adjustedHeight)
            .padding(.bottom, isSEDevice ? 24 : 60.adjustedHeight)
            .frame(maxWidth: 375.adjustedWidth, maxHeight: 800.adjustedHeight, alignment: .center)
            TransparentOverlayView(isPresented: viewModel.showToast) {
                VStack {
                    ToastView(message: viewModel.toastMessage)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity)) // 사라질 때는 페이드 아웃만
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: viewModel.showToast)
                .position(x: UIScreen.main.bounds.width / 2 + 10, y: UIScreen.main.bounds.height - 250)
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
                        
                        coordinator.shouldUpdateHomeView = false
                    }
                }
            }
            
        }
        .navigationDestination(for: HomePath.self) { path in
            switch path {
            case .setting:
                SettingView(coordinator: coordinator)
            case .petArchive:
                PetArchiveView(coordinator: coordinator, viewModel: PetArchiveViewModel(repository: HomeRepository()))
            case .successThreeDay(let totalKcal):
                ThreeDaySuccessView(coordinator: coordinator, totalKcal: totalKcal)
            case .newPet:
                NewPetView(coordinator: coordinator, viewModel: NewPetViewModel(homeRepository: HomeRepository(), coordinator: coordinator))
            case .upgradePet(let level, let petType):
                LevelUpView(coordinator: coordinator, level: level, petType: petType)
            }
        }
        .navigationBarHidden(true)
    }
}

extension HomeView {
    /// 네비게이션 바
    var navigationBar: some View {
        HStack(alignment: .center) {
            Button(action: {
                coordinator.push(to: .petArchive)
            }) {
                Image(.iconDocs)
            }
            .frame(width: 28.adjusted, height: 28.adjusted)
            Spacer()
            Button(action: {
                coordinator.push(to: .setting)
            }) {
                Image(.iconSetting)
            }
            .frame(width: 28.adjusted, height: 28.adjusted)
        }
        .frame(height: 30.adjusted)
        .background(.blue)
    }
    
    var kcalView: some View {
        HStack(alignment: .lastTextBaseline,spacing: 4) {
            Text("\(viewModel.currentKcal)")
                .font(.neoDunggeunmo52)
                .foregroundStyle(.white)
            Text("/")
                .font(.neoDunggeunmo42)
                .foregroundStyle(.white)
            Text("\(viewModel.homePetModel.goalKcal) kcal")
                .font(.neoDunggeunmo22)
                .foregroundStyle(.white)
        }
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
                    .frame(height: 400.adjusted)
            }
            VStack {
                Image(viewModel.bubbleImage)
                    .opacity(viewModel.showBubble ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.1), value: viewModel.showBubble)
                    .transition(.opacity)
                    .frame(minWidth: 75, maxWidth: 167, minHeight: 56)
                    .offset(y: viewModel.showBubble ? 10.adjustedHeight : 16)
                petImage
                    .onTapGesture {
                        viewModel.showRandomBubble(type: .normal)
                    }
            }
            .offset(y: isSEDevice ? 35.adjusted : 63.adjustedHeight)
        }
    }
    
    var petImage: some View {
        Group {
            if (viewModel.homePetModel.petType != .bluePenguin) {
                if viewModel.isPlayingSpecialAnimation {
                    LottieView(animation: .named(viewModel.currentLottieAnimation))
                        .playing(loopMode: .loop)
                        .frame(width: 100.adjusted, height: 100.adjusted)
                } else {
                    LottieView(animation: .named(viewModel.homePetModel.petType.lottieString(level: viewModel.homePetModel.level)))
                        .playing(loopMode: .loop)
                        .frame(width: 100.adjusted, height: 100.adjusted)
                }
            } else {
                viewModel.homePetModel.petType.image(for: viewModel.homePetModel.level)
                    .scaledToFit()
                    .frame(width: 100.adjusted, height: 100.adjusted)
            }
        }
    }
    
    var levelView: some View {
        VStack {
            HStack {
                Text("Lv.\(viewModel.homePetModel.level)")
                    .font(.neoDunggeunmo14)
                    .padding(4.adjusted)
                    .foregroundStyle(.white)
                    .background(.borderGray)
                    .cornerRadius(4)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.homePetModel.exp))
                    .font(.subTitle1_semibold14)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            ZStack(alignment: .leading) {
                Image(.gaugeBackground)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 28)
                // expCount 계산
                let expCount = min(Int(viewModel.homePetModel.exp) / 3, 28)
                
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
            HomeButton(buttonTitle: "먹이주기", count: viewModel.homePetModel.feedCount)
                .onTapGesture {
                    Task {
                        await viewModel.feedPet()
                    }
                }
            HomeButton(buttonTitle: "놀아주기", count: viewModel.homePetModel.toyCount)
                .onTapGesture {
                    Task {
                        await viewModel.playWithPet()
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
    }
}

#Preview {
    HomeView(coordinator: .init(), viewModel: HomeViewModel(repository: HomeRepository()))
}
