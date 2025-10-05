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
                        store.send(.createInviteCode)
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
                
                myProfileView
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private var friendsListView: some View {
        LazyVStack(spacing: 0) {
            WithPerceptionTracking {
                ForEach(store.friendsList.indices, id: \.self) { index in
                    friendsListItemView(friend: store.friendsList[index], index: index)
                }
            }
        }
    }

    func friendsListItemView(friend: Friend, index: Int) -> some View {
        
        return HStack {
            ZStack {
                Circle()
                    .fill(friend.mainPetType.color)
                    .frame(width: 48, height: 48)
                Image(friend.mainPetType.image(for: friend.petLevel))
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
                store.send(.deleteFriend(id: store.friendsList[index].id))
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
    
    var myProfileView: some View {
        WithPerceptionTracking {
            ZStack(alignment: .center) {
                Rectangle()
                    .frame(maxHeight: 72.adjustedHeight)
                    .particalCornerRadius(16.adjustedHeight, corners: .topLeft)
                    .particalCornerRadius(16.adjustedHeight, corners: .topRight)
                    .foregroundStyle(.borderGray)
                HStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .fill(store.state.myProfilePet.petType.color)
                            .frame(width: 48, height: 48)
                        Image(store.state.myProfilePet.petType.image(for: store.state.myProfilePet.level))
                            .resizable()
                            .frame(width: 42, height: 42)
                            .offset(y: -3)
                    }
                    .padding(.trailing, 12)
                    
                    Text(store.state.myProfilePet.name)
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
                .padding(.vertical, 12)
            }
        }
    }
}


//#Preview {
//    FriendListView(store: <#StoreOf<FriendsViewReducer>#>, coordinator: <#AppCoordinator#>)
//}
