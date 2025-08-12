//
//  RankContentsView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import SwiftUI
import ComposableArchitecture

struct RankContentsView: View {
    @State private var buttonWidth: CGFloat = 0
    @State private var scrollToIndex: Int? = nil
    
    var tabType: Tab
    
    @Perception.Bindable var store: StoreOf<RankViewReducer>
    
    var body: some View {
            ZStack {
                Color(.backgroundBlack)
                ZStack(alignment: .bottom) {
                    ScrollViewReader { proxy in
                        CustomScrollView {
                            VStack(alignment: .leading) {
                                headerView
                                    .zIndex(10)
                                    .padding(.bottom, 32)
                                rankContainerView
                            }
                        } onBottomReached: {
                            guard let totalGoalRanking = store.totalGoalRanking else { return }
                            guard let totalKcalRanking = store.totalKcalRanking  else { return }
                            let totalRankCount = tabType == .goal ? totalGoalRanking : totalKcalRanking
                            store.send(.showToast(totalRankCount < 100 ? "랭킹이 아직 \(totalRankCount)등까지 밖에 없어요" : "순위는 100위까지만 노출해요"))
                        }
                        .onReceive(store.publisher.focusedMyRankIndex.compactMap { $0 }) { index in
                            withAnimation {
                                proxy.scrollTo(index, anchor: .top)
                                store.send(.focusMyRank(index: 0))
                            }
                        }
                    }
                    myRankView
                    
                    TransparentOverlayView(isPresented: store.showToast, isDimView: false) {
                        VStack {
                            ToastView(message: store.toastMessage, toastType: .info)
                        }
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 320.adjustedHeight)
                    }
                }
                
                if shouldShowLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(.textButtonAlternative)
                        .background(Color.backgroundBlack)
                }
            }
            .onAppear {
                store.send(.tabChanged(tabType))
            }
            .onChange(of: tabType) { newTab in
                store.send(.tabChanged(newTab))
            }
        }
}

extension RankContentsView {
    var headerView: some View {
        VStack(alignment: .leading) {
            Text(setDateCirteria())
                .font(.body2_regular14)
                .foregroundStyle(.textBodyTeritary)
                .padding(.leading, 20)
                .padding(.top, 24)
            VStack(alignment: .leading) {
                HStack(alignment: .bottom) {
                    Text(tabType.GuideTitle)
                        .font(.neoDunggeunmo24)
                        .foregroundStyle(.textButtonAlternative)
                        .id(tabType)
                        .padding(.leading, 20)
                    
                    ZStack {
                        Button(
                            action: {
                                store.send(.toolkitButtonTapped)
                            },
                            label: {
                                Image(.iconInfomation)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                        )
                        .frame(width: 20, height: 24)
                        if store.showToolKit {
                            TooltipView(textString: tabType.toolKitMessage)
                                .fixedSize(horizontal: true, vertical: true)
                                .offset(y: tabType == .kcal ? 38.adjusted : 48.adjusted)
                                .alignmentGuide(.bottom) { _ in 0 }
                        }
                    }
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 20)
                }
            }
        }
    }
    
    var rankContainerView: some View {
        VStack {
            topRankView
                .padding(.bottom, 20)
            rankListView
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
    
    var topRankView: some View {
        WithPerceptionTracking {
            let ranking = currentRankingData
            let sortedRanking = Array(ranking.prefix(3).sorted(by: { $0.rank < $1.rank }))
            
            return HStack(alignment: .center, spacing: 12) {
                if sortedRanking.count == 3 {
                    RankCard(ranking: sortedRanking[1], tabType: tabType)
                    
                    RankCard(ranking: sortedRanking[0], tabType: tabType)
                        .offset(y: -19)
                    
                    RankCard(ranking: sortedRanking[2], tabType: tabType)
                } else {
                    ForEach(sortedRanking, id: \.userID) { ranking in
                        RankCard(ranking: ranking, tabType: tabType)
                    }
                }
            }
            .frame(height: 205.adjustedHeight)
            .frame(maxWidth: .infinity)
        }
    }
    
    var rankListView: some View {
        WithPerceptionTracking {
            let rankers = Array(currentRankingData.dropFirst(3))
            
            LazyVStack(spacing: 0) {
                ForEach(rankers.indices, id: \.self) { index in
                    rankListItemView(rank: rankers[index], index: index)
                }
            }
            .padding(.bottom, 100.adjustedHeight)
        }
    }
    
    func rankListItemView(rank: Ranking, index: Int) -> some View {
        let isMyRank: Bool = rank.userID == currentMyRanking?.userID
        
        return HStack(alignment: .center, spacing: 0) {
            Text("\(rank.rank)")
                .foregroundStyle(.textButtonAlternative)
                .font(.neoDunggeunmo16)
                .frame(width: 24, alignment: .leading)
                .padding(.trailing, 12)
            
            ZStack {
                Circle()
                    .fill(rank.mainPetType.color)
                    .frame(width: 48, height: 48)
                Image(rank.mainPetType.image(for: rank.petLevel))
                    .resizable()
                    .frame(width: 38, height: 38)
                    .offset(y: rank.petLevel > 3 ? 0 : -3)
                    .padding(3)
            }
            .padding(.trailing, 12)
            
            Text(rank.userName)
                .foregroundStyle(.textHeadlinePrimary)
                .font(.body1_regular16)
                .padding(.leading, 10)
            
            Text("나")
                .foregroundStyle(.textButtonPrimaryDefault)
                .font(.caption1_regular11)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.textHeadlinePrimary)
                .clipShape(Circle())
                .opacity(isMyRank ? 1 : 0)
                .padding(.leading, 8)
            
            Spacer()
            
            Text(tabType == .kcal ? "\(rank.totalCalories)" : "+\(rank.totalSucceededDays)")
                .foregroundStyle(.textButtonAlternative)
                .font(.body1_bold16)
                .padding(.trailing, 2)
            
            Text(tabType == .kcal ? "kcal" : "일")
                .foregroundStyle(.textButtonAlternative)
                .font(.body2_regular14)
        }
        .frame(height: 48)
        .frame(minWidth: 320, maxWidth: .infinity)
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }
    
    var myRankView: some View {
        WithPerceptionTracking {
            let myRanking = currentMyRanking
            
            ZStack(alignment: .center) {
                Rectangle()
                    .frame(maxHeight: 100.adjustedHeight)
                    .particalCornerRadius(16.adjustedHeight, corners: .topLeft)
                    .particalCornerRadius(16.adjustedHeight, corners: .topRight)
                    .foregroundStyle(.borderGray)
                HStack(alignment: .center) {
                    Text(String(myRanking?.rank ?? 0))
                        .font(.neoDunggeunmo16)
                        .foregroundStyle(.textButtonAlternative)
                        .padding(.trailing, 12)
                    ZStack {
                        Circle()
                            .fill(myRanking?.mainPetType.color ?? .blueGraphics)
                            .frame(width: 48, height: 48)
                        Image(myRanking?.mainPetType.image(for: myRanking?.petLevel ?? 0) ?? .blueEgg)
                            .resizable()
                            .frame(width: 42, height: 42)
                            .offset(y: -3)
                    }
                    .padding(.trailing, 12)
                    
                    Text(myRanking?.userName ?? "")
                        .font(.body1_regular16)
                        .foregroundStyle(.textBodyTeritary)
                    Text("나")
                        .foregroundStyle(.textButtonPrimaryDefault)
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.textHeadlinePrimary)
                        .clipShape(Circle())
                    Spacer()
                    Text(tabType == .kcal ? String(myRanking?.totalCalories ?? 0) : "+" + String(myRanking?.totalSucceededDays ?? 0))
                        .font(.body1_bold16)
                        .foregroundStyle(.textButtonAlternative)
                    Text(tabType == .kcal ? "kcal" : "일")
                        .font(.body1_regular16)
                        .foregroundStyle(.textButtonAlternative)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .onTapGesture {
                store.send(.focusMyRank(index: myRanking?.rank ?? 0))
            }
        }
    }
}

extension RankContentsView {
    private var currentRankingData: [Ranking] {
        (tabType == .kcal ? store.kcalRanking?.ranking : store.goalRanking?.ranking) ?? []
    }
    
    private var currentMyRanking: Ranking? {
        tabType == .kcal ? store.kcalRanking?.myRanking : store.goalRanking?.myRanking
    }
    
    private var shouldShowLoading: Bool {
        if store.dataLoadingState != .loadingFromCache {
            return true
        }
        
        let currentTabData = tabType == .kcal ? store.kcalRanking : store.goalRanking
        let currentTabLoadingState = tabType == .kcal ? store.kcalLoadingState : store.goalLoadingState
        
        return currentTabData == nil && currentTabLoadingState == .loadingFromNetwork
    }
    
    func setDateCirteria() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 기준"
        
        let dateCriteria = dateFormatter.string(from: Date())
        return dateCriteria
    }
    
    struct TextSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
}

struct RankCard: View {
    let ranking: Ranking
    let tabType: Tab
    
    var body: some View {
        ZStack {
            VStack {
                Image(ranking.mainPetType.image(for: ranking.petLevel))
                    .resizable()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 10)
                VStack {
                    Text(ranking.userName)
                        .font(.body2_regular14)
                        .foregroundStyle(Color.textBodyTeritary)
                        .frame(width: 82)
                        .lineLimit(1)
                        .lineSpacing(24)
                    Text(tabType == .kcal ? "\(ranking.totalCalories)kcal" : "+\(ranking.totalSucceededDays)일")
                        .font(.body1_bold16)
                        .foregroundStyle(Color.textButtonAlternative)
                }
            }
            .frame(width: 98.adjustedWidth, height: 152.adjustedHeight)
            .background(Color.backgroundGray)
            .cornerRadius(8)
            
            getCrownImage(for: ranking.rank)
                .offset(y: -76.adjustedHeight)
        }
        .padding(.horizontal, 6)
    }
    
    func getCrownImage(for index: Int) -> Image {
        switch index {
        case 1: return Image(.iconCrownFirst)
        case 2: return Image(.iconCrownSecond)
        case 3: return Image(.iconCrownThrid)
        default: return Image(.iconCrownFirst)
        }
    }
}

#Preview {
    RankContentsView(
        tabType: .goal,
        store: Store(
            initialState: RankViewReducer.State(),
            reducer: {
                RankViewReducer()
            }
        ))
}
