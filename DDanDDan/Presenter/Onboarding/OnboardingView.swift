//
//  OnboardingView.swift
//  DDanDDan
//
//  Created by hwikang on 6/28/24.
//

import SwiftUI
import HealthKit

struct OnboardingView: View {
    @State private var currentPageIndex: Int = 0
    @State private var showAuthDialog = false
    @State private var showSignup = false
    
    let coordinator: AppCoordinator
    
    private let pageItemList: [OnboardingItem] = [
        .init(title: "오늘 소비한 칼로리로\n귀여운 펫을 키워보세요", image: .onboarding1),
        .init(title: "펫이 다 자라면\n또 다른 펫을 키울 수 있어요", image: .onboarding2),
        .init(title: "꾸준히 운동해\n소중한 펫을 지켜주세요!", image: .onboarding3)
    ]
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    var body: some View {
        ZStack {
            Color.backgroundBlack.edgesIgnoringSafeArea(.all)
            VStack {
                TabView(selection: $currentPageIndex) {
                    ForEach(0..<pageItemList.count, id: \.self) { index in
                        OnboardingItemView(item: pageItemList[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack(spacing: 12) {
                    ForEach(0..<pageItemList.count, id: \.self) { index in
                        Rectangle()
                            .fill(index == currentPageIndex ? Color.greenGraphics : Color.borderGray)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPageIndex)
                    }
                }
                .padding(.vertical, 19)
                
                Button {
                    AnalyticsManager.shared.logEvent(event: OnboardingEvent.clickCTA())
                    if UserDefaultValue.requestAuthDone {
                        UserDefaultValue.needToShowOnboarding = false
                        coordinator.setRoot(to: .login)
                    } else {
                        showAuthDialog.toggle()
                    }

                } label: {
                    Text("시작하기")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .background(Color(red: 19/255, green: 230/255, blue: 149/255))
                        .foregroundColor(.black)
                }
                .fullScreenCover(isPresented: $showAuthDialog, content: {
                    DialogView(show: $showAuthDialog, title: "건강 데이터 접근 권한을 허용해주세요", description: "서비스 이용을 위하여 건강데이터\n 접근 권한이 필요합니다.", rightButtonTitle: "허용", leftButtonTitle: "허용안함") {
                        AnalyticsManager.shared.logEvent(event: OnboardingEvent.clickDisagreeDialogBtn())
                    } rightButtonHandler: {
                        AnalyticsManager.shared.logEvent(event: OnboardingEvent.clickAgreeDialogCTA())
                        HealthKitManager.shared.requestAuthorization { isEnable in
                            if isEnable {
                                UserDefaultValue.requestAuthDone = true
                                showSignup.toggle()
                                HealthKitManager.shared.readActiveEnergyBurned { energy in
                                    print(energy)
                                    coordinator.setRoot(to: .login)
                                }
                            }
                        }
                    }
                })
                .background(Color.backgroundGray)
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
                .padding(.bottom, 20)
            }
        }
        
    }
}

#Preview {
    OnboardingView(coordinator: .init())
}

struct OnboardingItem: Hashable {
    public let title: String, image: ImageResource
    init(title: String, image: ImageResource) {
        self.title = title
        self.image = image
    }
}

struct OnboardingItemView: View {
    private let item: OnboardingItem
    init(item: OnboardingItem) {
        self.item = item
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(item.title)
                .font(.neoDunggeunmo24)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 48)
                .padding(.bottom, 28)
            Image(item.image)
                .resizable()
                .frame(maxWidth: .infinity)
                .padding(0)
                .aspectRatio(contentMode: .fit)
            Spacer()
        }
    }
}
