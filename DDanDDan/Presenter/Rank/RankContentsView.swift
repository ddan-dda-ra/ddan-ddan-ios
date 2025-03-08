//
//  RankContentsView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import SwiftUI

struct RankContentsView: View {
    @State private var textWidth: CGFloat = 0 // Text 너비 저장
    @State private var showTooltip = false // 툴팁 표시 여부
    var tabType: Tab
       
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
            ScrollView {
                VStack(alignment: .leading) {
                    Text("2025년 5월 기준")
                        .font(.body2_regular14)
                        .foregroundStyle(.textBodyTeritary)
                    VStack(alignment: .leading) {
                        HStack(alignment: .bottom){
                            Text(tabType.GuideTitle)
                                .font(.neoDunggeunmo24)
                                .foregroundStyle(.textButtonAlternative)
                                .background(GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            textWidth = geo.size.width
                                        }
                                })
                            Button(
                                action: {
                                    withAnimation {
                                        showTooltip.toggle()
                                    }
                                },
                                label: {
                                    Image(.iconInfomation)
                                        .frame(width: 20, height: 20)
                                }
                            )
                        }
                        ZStack {
                            if showTooltip {
                                ToolKitView(textString: tabType.toolKitMessage)
                                    .offset(x: textWidth / 2 - 20)
                            }
                        }
                        .frame(height: 32)
                    }
                    rankContainerView
                }
                .frame(maxWidth: .infinity)
                //TODO: 내 랭킹
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity)
            .scrollIndicators(.hidden)
        }
        
    }
}

extension RankContentsView {
    var rankContainerView: some View {
        VStack {
            rankView
                .padding(.bottom, 20)
            rankListView
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
    
    var rankView: some View {
        HStack {
            ZStack {
                VStack {
                    Image(.blueLv1)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.bottom, 10)
                    VStack {
                        Text("알콩일이삼사오오")
                            .font(.body2_regular14)
                            .foregroundStyle(Color.textBodyTeritary)
                            .frame(width: 82)
                            .lineLimit(1)
                            .lineSpacing(24)
                        Text("\(200)kcal")
                            .font(.body1_bold16)
                            .foregroundStyle(Color.textButtonAlternative)
                    }
                }
                .frame(width: 98, height: 152)
                .background(Color.buttonAlternative)
                .cornerRadius(8)
                Image(.iconCrownSecond)
                    .offset(y: -76)
            }
            .padding(.horizontal, 10)
            ZStack {
                VStack {
                    Image(.pinkLv3)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.bottom, 10)
                    VStack {
                        Text("알콩일이삼사오오")
                            .font(.body2_regular14)
                            .foregroundStyle(Color.textBodyTeritary)
                            .frame(width: 82)
                            .lineLimit(1)
                            .lineSpacing(24)
                        Text("\(200)kcal")
                            .font(.body1_bold16)
                            .foregroundStyle(Color.textButtonAlternative)
                    }
                }
                .frame(width: 98, height: 152)
                .background(Color.buttonAlternative)
                .cornerRadius(8)
                
                Image(.iconCrownFirst)
                    .offset(y: -76)
            }
            .frame(height: 205)
            .cornerRadius(8)
            .padding(.bottom, 19)
            ZStack {
                VStack {
                    Image(.purpleLv2)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.bottom, 10)
                    VStack {
                        Text("알콩일이삼사오오")
                            .font(.body2_regular14)
                            .foregroundStyle(Color.textBodyTeritary)
                            .frame(width: 82)
                            .lineLimit(1)
                            .lineSpacing(24)
                        Text("\(200)kcal")
                            .font(.body1_bold16)
                            .foregroundStyle(Color.textButtonAlternative)
                    }
                }
                .frame(width: 98, height: 152)
                .background(Color.buttonAlternative)
                .cornerRadius(8)
                .padding(.horizontal, 10)
                
                Image(.iconCrownThrid)
                    .offset(y: -76)
            }
        }
        .frame(height: 205)
    }
    
    var rankListView: some View {
        let columView: [GridItem] = [
            .init(spacing: 0),
            .init(spacing: 0),
            .init(spacing: 0),
            .init(spacing: 0),
            .init(spacing: 0),
            .init(spacing: 0),
            .init(spacing: 0)
        ]
        
        return ScrollView {
            LazyHGrid(rows: columView, spacing: 0) { // spacing 0으로 설정
                ForEach(columView.indices) { _ in
                    rankListItemView
                }
            }
        }
    }
    
    var rankListItemView: some View {
        HStack(alignment: .center, spacing: 0) { // spacing 0
            Text("4")
                .foregroundStyle(.textButtonAlternative)
                .font(.neoDunggeunmo16)
                .frame(width: 24, alignment: .leading)
            
            Image(.greenEgg)
                .resizable()
                .frame(width: 48, height: 48, alignment: .center)
                .background(Color.greenGraphics)
                .cornerRadius(24)
            
            Text("닉네임")
                .foregroundStyle(.textHeadlinePrimary)
                .font(.body1_regular16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Spacer()
            
            Text("234")
                .foregroundStyle(.textButtonAlternative)
                .font(.body1_bold16)
                .padding(.trailing, 2)
            
            Text("kcal")
                .foregroundStyle(.textButtonAlternative)
                .font(.body2_regular14)
        }
        .frame(width: 320, height: 48)
        .padding(.bottom, 20)
    }
}

#Preview {
    RankContentsView(tabType: .goal)
}
