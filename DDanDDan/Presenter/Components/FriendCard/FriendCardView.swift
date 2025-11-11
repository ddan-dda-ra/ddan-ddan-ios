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
    
    init(store: StoreOf<FriendCardReducer>) {
        self.store = store
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.backgroundBlack).ignoresSafeArea().opacity(0.7)
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
            .background(BackgroundBlurView().ignoresSafeArea())
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
                Button(action: handleButtonTap) {
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
            if store.fireAnimation {
                FireEmitterView()
                    .frame(width: 296, height: 300)
                    .padding(.top, -10)
                    .allowsHitTesting(false)
            }
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
            HStack(alignment: .center, spacing: 0) {
                Image(.fire)
                    .resizable()
                    .frame(width: 20, height: 20)
                
                Text("받은 응원")
                    .font(.body1_regular16)
                    .foregroundStyle(.textBodyTeritary)
                    .padding(.leading, 2)
                
                Text("\(store.entity?.monthlyReceivedCheerCount ?? 0)")
                    .font(.neoDunggeunmo24)
                    .baselineOffset(-2)
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
                HStack(spacing: 2) {
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
    
    private func handleButtonTap() {
        switch store.type {
        case .invite:
            store.send(.onTapButton)
            dismiss()
        case .cheer:
            store.send(.onTapButton)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

// MARK: - Fire Emitter View
struct FireEmitterView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitterLayer = CAEmitterLayer()
        
        // 방출 위치 (중앙 하단에서 시작)
        emitterLayer.emitterPosition = CGPoint(x: 148, y: 200)
        
        // 불꽃 셀 생성
        emitterLayer.emitterCells = [createFireCell()]
        emitterLayer.birthRate = 1
        
        view.layer.addSublayer(emitterLayer)
        
        // 자동으로 애니메이션 종료
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitterLayer.birthRate = 0
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func createFireCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "fire")?.cgImage
        
        cell.lifetime = 1.5
        cell.lifetimeRange = 0.5
        
        
        cell.birthRate = 35
        
        
        cell.scale = 0.8
        cell.scaleRange = 0.15
        
        
        cell.alphaSpeed = -0.9
        
        
        cell.spin = 0.2
        cell.spinRange = 1.0
        
        
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 1.8
        
        
        cell.velocity = 160
        cell.velocityRange = 50
        
        
        cell.yAcceleration = -120
        
        return cell
    }
}


#Preview {
    FriendCardView(
        store: Store(
            initialState: FriendCardReducer.State(
                userID: "67cc3acbb0b10655fa4a37d6",
                entity: .init(userId: "67cc3acbb0b10655fa4a37d6", userName: "지희", mainPet: .init(id: "", type: .greenHam, level: 2, expPercent: 29), todayCalorie: 100, monthlyReceivedCheerCount: 12, isFriend: true, isCheeredToday: false), type: .cheer
            )
        ) {
            FriendCardReducer()
        }
    )
}
