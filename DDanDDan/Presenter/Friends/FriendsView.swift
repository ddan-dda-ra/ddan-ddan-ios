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
        WithPerceptionTracking {
            ZStack {
                Color(.backgroundBlack).ignoresSafeArea()
                VStack {
                    HStack {
                        Text("친구 목록")
                            .foregroundStyle(Color.textButtonAlternative)
                            .font(.neoDunggeunmo24)
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
                    
                    ScrollView {
                        friendsListView
                            .frame(maxWidth: .infinity)
                    }
                    .refreshable {
                        await store.send(.refreshFriendsList).finish()
                    }
                    
                    Spacer()
                    
                    myProfileView
                }
                
                // Toast View
                if store.showToast {
                    TransparentOverlayView(isPresented: store.showToast, isDimView: false) {
                        VStack {
                            ToastView(message: store.toastMessage, toastType: .check)
                        }
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 250.adjustedHeight)
                    }
                }
                
                // Delete Alert
                if store.deleteFriendAlert {
                    TransparentOverlayView(isPresented: store.deleteFriendAlert, isDimView: true) {
                        DialogView(
                            show: $store.deleteFriendAlert,
                            title: "정말 삭제하시겠어요?",
                            description: "친구가 삭제돼요",
                            rightButtonTitle: "삭제하기",
                            leftButtonTitle: "취소"
                        ) {
                            store.send(.confirmDelete)
                        }
                    }
                }
            }
            .fullScreenCover(store: store.scope(state: \.$friendCard, action: \.friendCard), content: { store in
                FriendCardView(store: store)
            })
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

    func friendsListItemView(friend: Friend, index: Int) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(friend.mainPetType.color)
                    .frame(width: 48, height: 48)
                Image(friend.mainPetType.image(for: friend.petLevel))
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding(3)
            }
            .padding(.trailing, 12)
            
            Text(friend.name)
                .foregroundStyle(.textHeadlinePrimary)
                .font(.body1_regular16)
            
            Spacer()
            
            Button {
                store.send(.showDeleteAlert(id: store.friendsList[index].id))
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
        .onTapGesture {
            print("tap!!!")
            store.send(.onTapItem(friend))
        }
    }
    
    var myProfileView: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .frame(maxHeight: 72.adjustedHeight)
                .particalCornerRadius(16.adjustedHeight, corners: .topLeft)
                .particalCornerRadius(16.adjustedHeight, corners: .topRight)
                .foregroundStyle(.borderGray)
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(store.myProfilePet.petType.color)
                        .frame(width: 48, height: 48)
                    Image(store.myProfilePet.petType.image(for: store.myProfilePet.level))
                        .resizable()
                        .frame(width: 42, height: 42)
                        .offset(y: -3)
                }
                .padding(.trailing, 12)
                
                Text(store.myProfilePet.name)
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
