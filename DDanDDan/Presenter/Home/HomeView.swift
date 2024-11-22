//
//  HomeView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI
import HealthKit

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
    
    var body: some View {
        
        ZStack {
            Color(.backgroundBlack)
                .ignoresSafeArea()
            VStack {
                navigationBar
                    .padding(.bottom, 16)
                kcalView
                    .padding(.bottom, 14)
                ZStack {
                    viewModel.homePetModel.petType.backgroundImage
                        .scaledToFit()
                        .padding(.horizontal, 53)
                        .clipped()
                    viewModel.homePetModel.petType.image(for: viewModel.homePetModel.level)
                        .scaledToFit()
                        .padding(.horizontal, 141)
                        .offset(y: 95)
                        .onTapGesture {
                            viewModel.showRandomBubble(type: .normal)
                        }
                    bubbleView
                        .opacity(viewModel.showBubble ? 1 : 0)
                        .transition(.opacity)
                        .frame(minWidth: 75, maxWidth: 167, minHeight: 56)
                        .offset(y: 20)
                }
                .padding(.bottom, 32)
                levelView
                    .padding(.bottom, 20)
                actionButtonView
            }
            .frame(maxHeight: .infinity, alignment: .top)
            TransparentOverlayView(isPresented: $viewModel.showToast) {
                VStack {
                    ToastView(message: viewModel.toastMessage)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity)) // 사라질 때는 페이드 아웃만
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: viewModel.showToast)
                .position(x: UIScreen.main.bounds.width / 2 + 10, y: UIScreen.main.bounds.height - 250)
            }
            TransparentOverlayView(isPresented: $viewModel.isPresentEarnFood) {
                ImageDialogView(
                    show: $viewModel.isPresentEarnFood,
                    image: .eatGraphic,
                    title: "먹이를 얻었어요!",
                    description: "사과 \(viewModel.earnFood)개",
                    buttonTitle: "획득하기"
                ) {
                    // 이후 동작 정의 -> 서버 통신 및 뷰 업데이트
                    Task {
                        await viewModel.patchCurrentKcal(earnedFeed: viewModel.earnFood)
                        viewModel.showRandomBubble(type: .success)
                    }
                }
            }
            .onChange(of: viewModel.isLevelUp) { newLevel in
                if newLevel {
                    coordinator.push( to: .upgradePet(
                        level: viewModel.homePetModel.level,
                        petType: viewModel.homePetModel.petType
                    )
                    )
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
                NewPetView(coordinator: coordinator, viewModel: NewPetViewModel(homeRepository: HomeRepository()))
            case .upgradePet(let level, let petType):
                LevelUpView(coordinator: coordinator, level: level, petType: petType)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.homePetModel.level == 0 {
                Task {
                    await viewModel.fetchHomeInfo()
                }
            }
        }
    }
}

extension HomeView {
    /// 네비게이션 바
    var navigationBar: some View {
        HStack {
            Button(action: {
                coordinator.push(to: .petArchive)
            }) {
                Image(.iconDocs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            
            Button(action: {
                coordinator.push(to: .setting)
            }) {
                Image(.iconSetting)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 20)
        }
    }
    
    var bubbleView: some View {
        ZStack {
            // 말풍선 이미지 선택 (글자 수에 따라 조정)
            Image(viewModel.bubbleImage)
                .opacity(viewModel.showBubble ? 1 : 0)
                .offset(y: viewModel.showBubble ? 0 : 20) // 초기 위치 조정
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: viewModel.showBubble) // 나타날 때 애니메이션
            
            Text(viewModel.bubbleText)
                .font(.neoDunggeunmo14)
                .foregroundStyle(.backgroundBlack)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .opacity(viewModel.showBubble ? 1 : 0)
                .offset(y: viewModel.showBubble ? -8 : 20) // 텍스트 위치 조정
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: viewModel.showBubble) // 나타날 때 애니메이션
        }
    }
    
    var kcalView: some View {
        HStack(spacing: 4) {
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
    
    var levelView: some View {
        VStack {
            HStack {
                Text("Lv.\(viewModel.homePetModel.level)")
                    .font(.neoDunggeunmo14)
                    .padding(4)
                    .foregroundStyle(.white)
                    .background(.borderGray)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String(format: "%.0f%%", viewModel.homePetModel.exp))
                    .font(.subTitle1_semibold16)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            ZStack(alignment: .leading) {
                Image(.gaugeBackground)
                    .resizable()
                    .frame(height: 28)
                
                // expCount 계산
                let expCount = min(Int(viewModel.homePetModel.exp) / 3, 28)
                
                // Rectangle 생성
                HStack(spacing: 4) {  // HStack을 사용하여 왼쪽 정렬 및 패딩 처리
                    ForEach(0..<29, id: \.self) { index in
                        if index < expCount {
                            Rectangle()
                                .fill(viewModel.homePetModel.petType.color)
                                .frame(width: 8, height: 12)
                        } else {
                            Rectangle()
                                .fill(Color.clear)  // 비어 있는 부분은 투명하게
                                .frame(width: 8, height: 12)
                        }
                    }
                }
                .padding(.leading, 12) // 첫 번째 여백은 8, 그 외의 여백은 HStack 내에서 처리됨
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
    
    var actionButtonView: some View {
        HStack(spacing: 12) {
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
        .padding(.horizontal, 32)
    }
}

#Preview {
    HomeView(coordinator: .init(), viewModel: HomeViewModel(repository: HomeRepository()))
}
