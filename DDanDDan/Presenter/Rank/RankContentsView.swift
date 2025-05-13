//
//  RankContentsView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import SwiftUI

import ComposableArchitecture

struct RankContentsView: View {
    @State private var kcalGuideTextWidth: CGFloat = 173/2
    @State private var goalGuideTextWidth: CGFloat = 196/2
    @State private var buttonWidth: CGFloat = 0
    
    @State private var scrollToIndex: Int? = nil
    
    var tabType: Tab
    
    @Perception.Bindable var store: StoreOf<RankViewReducer>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.backgroundBlack)
                ZStack(alignment: .bottom) {
                    ScrollViewReader { proxy in
                        CustomScrollView {
                            VStack(alignment: .leading) {
                                headerView
                                    .zIndex(10)
                                rankContainerView
                            }
                        } onBottomReached: {
                            guard let totalGoalRanking = store.totalGoalRanking else { return }
                            guard let totalKcalRanking = store.totalKcalRanking  else { return }
                            let totalRankCount = tabType == .goal ? totalGoalRanking : totalKcalRanking
                            store.send(.setShowToast(true, totalRankCount < 100 ? "랭킹이 아직 \(totalRankCount)등까지 밖에 없어요" : "순위는 100위까지만 노출해요"))
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
                
                if store.isLoading && !(tabType == .kcal ? store.isKcalRankingLoaded : store.isGoalRankingLoaded) {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(.textButtonAlternative)
                        .background(Color.backgroundBlack)
                }
            }
        }
    }
}


extension RankContentsView {
    var headerView: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading) {
                Text(setDateCirteria())
                    .font(.body2_regular14)
                    .foregroundStyle(.textBodyTeritary)
                    .padding(.leading, 20)
                    .padding(.top, 24)
                VStack(alignment: .leading) {
                    WithPerceptionTracking {
                        HStack(alignment: .bottom) {
                            Text(tabType.GuideTitle)
                                .font(.neoDunggeunmo24)
                                .foregroundStyle(.textButtonAlternative)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                updateGuideTextWidth(width: geo.size.width)
                                            }
                                    }
                                )
                                .id(tabType)
                                .padding(.leading, 20)
                            Button(
                                action: {
                                    store.send(.setShowToolkit)
                                },
                                label: {
                                    Image(.iconInfomation)
                                        .frame(width: 20, height: 20)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .onAppear {
                                                        buttonWidth = geo.size.width
                                                    }
                                            }
                                        )
                                }
                            )
                        }
                    }
                    ZStack {
                        if store.showToolKit {
                            ToolKitView(textString: tabType.toolKitMessage)
                                .offset(x: (tabType.guideTitleWidth + 40).adjustedWidth,
                                        y: tabType == .kcal ? 10: 14)
                        }
                    }
                    .frame(height: 32)
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
            let viewStore = ViewStore(store, observe: { $0 })
            
            let ranking = (tabType == .kcal ? viewStore.kcalRanking?.ranking : viewStore.goalRanking?.ranking) ?? []
            let sortedRanking = ranking.prefix(3).sorted(by: { $0.rank < $1.rank })
            
            return HStack(alignment: .center, spacing: 12) {
                if sortedRanking.count == 3 {
                    RankCard(ranking: sortedRanking[1], tabType: tabType)
                    
                    RankCard(ranking: sortedRanking[0], tabType: tabType)
                        .offset(y: -19)
                    
                    RankCard(ranking: sortedRanking[2], tabType: tabType)
                } else {
                    ForEach(sortedRanking, id: \.rank) { ranking in
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
            let viewStore = ViewStore(store, observe: { $0 })
            let rankers = (tabType == .kcal ? viewStore.kcalRanking?.ranking.dropFirst(3) : viewStore.goalRanking?.ranking.dropFirst(3)) ?? []
            
            LazyVStack(spacing: 0) {
                ForEach(rankers.indices, id: \.self) { index in
                    WithPerceptionTracking {
                        rankListItemView(rank: rankers[index], index: index)
                            .id(index+1)
                    }
                }
            }
            .padding(.bottom, 100.adjustedHeight)
        }
    }
    
    
    func rankListItemView(rank: Ranking, index: Int) -> some View {
        let isMyRank: Bool = rank.userID == (tabType == .kcal ? store.kcalRanking?.myRanking.userID : store.goalRanking?.myRanking.userID)
        
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
        ZStack(alignment: .center) {
            Rectangle()
                .frame(maxHeight: 100.adjustedHeight)
                .particalCornerRadius(16.adjustedHeight, corners: .topLeft)
                .particalCornerRadius(16.adjustedHeight, corners: .topRight)
                .foregroundStyle(.borderGray)
            HStack(alignment: .center) {
                Text(String((self.tabType == .kcal ? store.kcalRanking?.myRanking.rank : store.goalRanking?.myRanking.rank) ?? 0))
                    .font(.neoDunggeunmo16)
                    .foregroundStyle(.textButtonAlternative)
                    .padding(.trailing, 12)
                ZStack {
                    Circle()
                        .fill(store.kcalRanking?.myRanking.mainPetType.color ?? .blueGraphics)
                        .frame(width: 48, height: 48)
                    Image(store.kcalRanking?.myRanking.mainPetType.image(for: store.kcalRanking?.myRanking.petLevel ?? 0) ?? .blueEgg)
                        .resizable()
                        .frame(width: 42, height: 42)
                        .offset(y: -3)
                }
                .padding(.trailing, 12)
                
                Text((self.tabType == .kcal ? store.kcalRanking?.myRanking.userName : store.goalRanking?.myRanking.userName) ?? "")
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
                Text(self.tabType == .kcal ? String(store.kcalRanking?.myRanking.totalCalories ?? 0) : "+" + String(store.goalRanking?.myRanking.totalSucceededDays ?? 0))
                    .font(.body1_bold16)
                    .foregroundStyle(.textButtonAlternative)
                Text(self.tabType == .kcal ? "kcal" : "일")
                    .font(.body1_regular16)
                    .foregroundStyle(.textButtonAlternative)
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .onTapGesture {
            store.send(.focusMyRank(index: currentRanking?.rank ?? 0))
        }
    }
}

extension RankContentsView {
    private var currentRanking: Ranking? {
        tabType == .kcal ? store.kcalRanking?.myRanking : store.goalRanking?.myRanking
    }
    
    private var currentRankingList: [Ranking] {
        (tabType == .kcal ? store.kcalRanking?.ranking : store.goalRanking?.ranking) ?? []
    }
    
    func setDateCirteria() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 기준"
        
        let dateCriteria = dateFormatter.string(from: Date())
        return dateCriteria
    }
    
    private func updateGuideTextWidth(width: CGFloat) {
        if tabType == .kcal {
            kcalGuideTextWidth = width
        } else {
            goalGuideTextWidth = width
        }
    }
    
    private func calculateToolkitXOffset() -> CGFloat {
        let horizontalPadding: CGFloat = 20
        let infoButtonWidth: CGFloat = 20
        let spacing: CGFloat = 8
        let textWidth: CGFloat = tabType == .kcal ? kcalGuideTextWidth : goalGuideTextWidth
        
        let totalWidth = textWidth + spacing + infoButtonWidth
        
        return horizontalPadding + (totalWidth / 2)
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
        default: return Image(.iconCrownFirst) // 기본값
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
