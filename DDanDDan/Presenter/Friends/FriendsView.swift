//
//  FriendListView.swift
//  DDanDDan
//
//  Created by 이지희 on 9/5/25.
//

import SwiftUI

import ComposableArchitecture

struct FriendListView: View {
    @Perception.Bindable var store: StoreOf<FriendsViewReducer>
    @ObservedObject var coordinator: AppCoordinator
    
    init(store: StoreOf<FriendsViewReducer>, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack).ignoresSafeArea()
            VStack {
                HStack {
                    Text("친구 목록")
                        .foregroundStyle(Color.textButtonAlternative)
                        .font(.neoDunggeunmo24) // 23으로 변경 필요
                    Spacer()
                    Button {
                        // 친구 추가
                    } label: {
                        Text("친구 추가")
                            .foregroundStyle(Color.textHeadlinePrimary)
                            .font(.subTitle1_semibold14)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.elevationLevel03)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72.adjustedHeight)
                .padding(.horizontal, 20)
                .padding(.bottom, 9)

                friendsListView
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                myRankView
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private var friendsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(store.friendsList.indices, id: \.self) { index in
                friendsListItemView(friend: store.friendsList[index], index: index)
            }
        }
    }

    func friendsListItemView(friend: FriendModel, index: Int) -> some View {
        
        return HStack {
            ZStack {
                Circle()
                    .fill(friend.petType.color)
                    .frame(width: 48, height: 48)
                Image(friend.petType.image(for: friend.level))
                    .resizable()
                    .frame(width: 38, height: 38)
                //                    .offset(y: rank.petLevel > 3 ? 0 : -3)
                    .padding(3)
            }
            .padding(.trailing, 12)
            
            Text(friend.name)
                .foregroundStyle(.textHeadlinePrimary)
                .font(.body1_regular16)
            
            Spacer()
            
            Button {
                // 친구 삭제
            } label: {
                Image(.deleteIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            
        }
        
        .frame(height: 48)
        .frame(maxWidth: .infinity)
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
                    ZStack {
                        Circle()
                            .fill(.pinkGraphics)
                            .frame(width: 48, height: 48)
                        Image(.pinkLv1)
                            .resizable()
                            .frame(width: 42, height: 42)
                            .offset(y: -3)
                    }
                    .padding(.trailing, 12)
                    
                    Text("NickName")
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
    }
}

struct FriendModel: Equatable {
    var name: String
    var petType: PetType
    var level: Int
}


//#Preview {
//    FriendListView(store: <#StoreOf<FriendsViewReducer>#>, coordinator: <#AppCoordinator#>)
//}
