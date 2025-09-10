//
//  FriendCardView.swift
//  DDanDDan
//
//  Created by keone on 9/10/25.
//

import ComposableArchitecture
import SwiftUI

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
    
    var body: some View {
        ZStack {
            Rectangle().fill(.clear).background(.thinMaterial)
                .ignoresSafeArea()
            
            cardView
        }
    }
    
    var cardView: some View {
        VStack {
            VStack {
                store.entity.mainPetType.seBackgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 296, height: 200)
                
                
                
            }
            .background(Color.elevationLevel03)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Button(action: {}) {
                Text(store.buttonTitle)
                    .font(.heading6_semibold16)
                    .foregroundStyle(Color.textButtonPrimaryDefault)
            }
            .frame(width: 136, height: 56)
            .background(Color.white)
        }
        .frame(width: 296, height: 489)

    }
    
    var cardContentView: some View {
        VStack {
            
            HStack {
                Text(store.entity.userName)
                
                Text("LV. \(store.entity.petLevel)")
            }
            
            Text("받은 응원 \(store.entity.cheerCount)")
            
            Text("오늘 소모 칼로리")
            Text("\(store.entity.totalCalories) kcal")
        }
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
