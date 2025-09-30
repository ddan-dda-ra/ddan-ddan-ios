//
//  FriendCardView.swift
//  DDanDDan
//
//  Created by keone on 9/10/25.
//

import ComposableArchitecture
import SwiftUI
import Lottie

struct FriendCardView: View {
    let store: StoreOf<FriendCardReducer>
    @Environment(\.dismiss) var dismiss
    let animatedFireCount = 12
    @State private var fireOffsetArray: [(x: CGFloat, y: CGFloat)]
    @State private var fireOpacity: Double = 0
    
    init(store: StoreOf<FriendCardReducer>) {
        self.store = store
        self.fireOffsetArray = Array(repeating: (x: 0, y: 0), count: animatedFireCount)
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                Group {
                    if store.entity != nil {
                        cardView
                        toastView
                    } else {
                        EmptyView()
                    }
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BackgroundBlurView())
            .onChange(of: store.dismiss) { isDismiss in
                if isDismiss {
                    dismiss()
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    var cardView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                cardImageView
                cardContentView
            }
            .background(Color.elevationLevel01)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !store.hideButton {
                Button(action: { store.send(.onTapButton)}) {
                    Text(store.buttonTitle)
                        .font(.heading6_semibold16)
                        .foregroundStyle(Color.textButtonPrimaryDefault)
                }
                .frame(width: 136, height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

        }
        .overlay(alignment: .top) {
            animatedFireView
                .padding(.top, 77)
        }
        .frame(width: 296, height: 489)
        
    }
    
    var toastView: some View {
        TransparentOverlayView(isPresented: store.showToast, isDimView: false) {
            VStack {
                ToastView(message: store.toastMessage, toastType: .info)
            }
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 230.adjustedHeight)
        }
    }
    
    var cardImageView: some View {
        store.petBackgroundImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 296, height: 200)
            .overlay(alignment: .topLeading) {
                if let badgeTitle = store.badgeTitle {
                    Text(badgeTitle)
                        .font(.heading7_medium16)
                        .foregroundStyle(.textHeadlinePrimary)
                        .padding(4)
                        .background(.elevationLevel04)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(16)
                }
            }
            .overlay(alignment: .bottom) {
                LottieView(
                    animation: .named(store.petLottieStrng))
                .playing(loopMode: .loop)
                .frame(width: 100, height: 100)
                .padding(.bottom, 23)
            }
            .overlay(alignment: .topTrailing) {
                Image(.close)
                    .padding(16)
                    .onTapGesture {
                        dismiss()
                    }
            }
            .onChange(of: store.fireAnimation) { fireAnimation in
                if fireAnimation {
                    print("@@ fireAnimation")
                    Task {
                        await performFireAnimation()
                    }
                }
            }
    }
    
   
    
    var cardContentView: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 8) {
                Text(store.entity?.userName ?? "")
                    .font(.neoDunggeunmo22)
                    .foregroundStyle(.textHeadlinePrimary)
                
                Text("LV.\(store.entity?.mainPet.level ?? 0)")
                    .font(.neoDunggeunmo16)
                    .foregroundStyle(.textHeadlinePrimary)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .background(.elevationLevel02)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            HStack(spacing: 0) {
                Image(.fire)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("받은 응원")
                    .font(.body1_regular16)
                    .foregroundStyle(.textBodyTeritary)
                    .padding(.leading, 2)
                
                Text("\(store.entity?.monthlyReceivedCheerCount ?? 0)")
                    .font(.neoDunggeunmo24)
                    .foregroundStyle(.textBodyTeritary)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(.elevationLevel02)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.top, 13)
            
            Rectangle()
                .fill(.elevationLevel02)
                .frame(height: 1)
                .padding(.vertical, 20)
            
            VStack(spacing: 3) {
                Text("오늘 소모 칼로리")
                    .font(.body1_regular16)
                    .foregroundStyle(.textBodyTeritary)
                HStack(spacing: 0) {
                    Text("\(store.entity?.todayCalorie ?? 0)")
                        .font(.neoDunggeunmo20)
                        .foregroundStyle(.textHeadlinePrimary)
                    Text("kcal")
                        .font(.neoDunggeunmo14)
                        .foregroundStyle(.textHeadlinePrimary)
                }
                
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
    }
    
    var animatedFireView: some View {
        ZStack {
            ForEach(0 ..< animatedFireCount, id: \.self) { index in
                if index < fireOffsetArray.count {
                    Image(.fire)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .offset(
                            x: fireOffsetArray[index].x,
                            y: fireOffsetArray[index].y
                        )
                        .opacity(fireOpacity)
                }
            }
        }
    }
    
    private func performFireAnimation() async {
        withAnimation(.easeOut(duration: 0.4)) {
            fireOffsetArray = fireOffsetArray.map { _ in
                (randomOffset(), randomOffset())
            }
            fireOpacity = 1
        }
        
        try? await Task.sleep(for: .seconds(0.5))
        
        withAnimation(.easeIn(duration: 0.5)) {
            fireOffsetArray = fireOffsetArray.map { (x, y) in
                (x, 500)
            }
            fireOpacity = 0
        }
        
        try? await Task.sleep(for: .seconds(0.5))
        fireOffsetArray = fireOffsetArray.map { _ in (0, 0) }
    }
    
    private func randomOffset() -> CGFloat {
        CGFloat.random(in: -100...100)
    }
}
