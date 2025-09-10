//
//  FriendCardView.swift
//  DDanDDan
//
//  Created by keone on 9/10/25.
//

import ComposableArchitecture
import SwiftUI
import Lottie

struct FriendCardEntity: Equatable {
    let userID: String
    let userName: String
    let mainPetType: PetType
    let petLevel: Int
    let totalCalories: Int
    let cheerCount: Int
}

struct FriendCardView: View {
    let store: StoreOf<FriendCardReducer>
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            cardView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundBlurView())
    }
    
    var cardView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                
                cardImageView
                cardContentView
                
            }
            .background(Color.elevationLevel01)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Button(action: {}) {
                Text(store.buttonTitle)
                    .font(.heading6_semibold16)
                    .foregroundStyle(Color.textButtonPrimaryDefault)
            }
            .frame(width: 136, height: 56)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))

        }
        .frame(width: 296, height: 489)
    }
    
    var cardImageView: some View {
        store.entity.mainPetType.cardBackgroundImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 296, height: 200)
            .overlay(alignment: .bottom) {
                LottieView(
                    animation: .named(store.entity.mainPetType.lottieString(level: store.entity.petLevel)))
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
                Text(store.entity.userName)
                    .font(.neoDunggeunmo22)
                    .foregroundStyle(.textHeadlinePrimary)
                
                Text("LV.\(store.entity.petLevel)")
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
                
                Text("\(store.entity.cheerCount)")
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
                .frame(height: 1)
                .background(.elevationLevel02)
                .padding(.vertical, 20)
            
            VStack(spacing: 3) {
                Text("오늘 소모 칼로리")
                    .font(.body1_regular16)
                    .foregroundStyle(.textBodyTeritary)
                HStack(spacing: 0) {
                    Text("\(store.entity.totalCalories)")
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
}

@Reducer
struct FriendCardReducer {
    
    enum CardType {
        case cheer
        case invite
    }
    
    @ObservableState
    struct State: Equatable {
        let entity: FriendCardEntity
        let type: CardType
        var buttonTitle: String {
            switch type {
            case .cheer: "응원하기"
            case .invite: "친구하기"
            }
        }
    }
    enum Action {
        
    }
}
