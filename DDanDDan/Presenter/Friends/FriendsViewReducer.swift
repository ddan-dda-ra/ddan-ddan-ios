//
//  FriendsViewReducer.swift
//  DDanDDan
//
//  Created by 이지희 on 9/23/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct FriendsViewReducer {
    let repository: FriendRepositoryProtocol
    private let linkBuilder = InviteLinkBuilder(
        baseInviteURL: URL(string: "https://ddanddan.chottu.link")!
    )

    init(repository: FriendRepositoryProtocol = FriendRepository()) {
        self.repository = repository
    }
    
    @ObservableState
    struct State: Equatable {
        var friendsList: [Friend] = []
        var isLoading = false
        var hasLoadedOnce = false
        var errorMessage: String?
        var myProfilePet: ProfileModel = .init(
            name: UserDefaultValue.nickName,
            petType: PetType(rawValue: UserDefaultValue.petType) ?? .pinkCat,
            level: UserDefaultValue.level
        )
        var inviteCode: String = ""
        var lastCopiedURL: URL?
        
        // 삭제 관련 상태
        var deleteFriendAlert: Bool = false
        var friendToDelete: String? = nil
        
        var showToast: Bool = false
        var toastMessage: String = ""
        
        // Scope
        @Presents var friendCard: FriendCardReducer.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case refreshFriendsList
        case friendsListResponse(Result<FriendList, NetworkError>)
        case myProfileLoaded(ProfileModel)
        
        case onTapItem(Friend)
        case showDeleteAlert(id: String)
        case confirmDelete
        case deleteFriendResponse(id: String, Result<EmptyEntity, NetworkError>)
        
        case createInviteCode
        case createInviteCodeResponse(Result<InviteCode, NetworkError>)
        case dismissToast
        
        //Scope
        case friendCard(PresentationAction<FriendCardReducer.Action>)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.myProfilePet = .init(
                    name: UserDefaultValue.nickName,
                    petType: PetType(rawValue: UserDefaultValue.petType) ?? .pinkCat,
                    level: UserDefaultValue.level
                )
                guard !state.hasLoadedOnce && !state.isLoading else {
                    return .none
                }
                state.isLoading = true
                return loadFriendsList()
                
            case .refreshFriendsList:
                state.isLoading = true
                return loadFriendsList()
                
            case let .friendsListResponse(.success(friendsList)):
                state.isLoading = false
                state.hasLoadedOnce = true
                state.friendsList = friendsList.friends
                state.errorMessage = nil
                return .none
                
            case let .friendsListResponse(.failure(error)):
                state.isLoading = false
                state.hasLoadedOnce = true
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .myProfileLoaded(profile):
                state.myProfilePet = profile
                return .none
                
            case let .onTapItem(friend):
                state.friendCard = .init(userID: friend.id, type: .cheer)
                return .none
                
            case let .showDeleteAlert(id):
                state.friendToDelete = id
                state.deleteFriendAlert = true
                return .none
                
            case .confirmDelete:
                guard let friendId = state.friendToDelete else { return .none }
                state.deleteFriendAlert = false
                state.friendToDelete = nil
                return deleteFriend(id: friendId)
                
            case let .deleteFriendResponse(id, .success):
                state.friendsList.removeAll { $0.id == id }
                state.showToast = true
                state.toastMessage = "친구가 삭제되었어요."
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.dismissToast)
                }
                
            case let .deleteFriendResponse(_, .failure(error)):
                state.showToast = true
                state.toastMessage = "친구 삭제에 실패했어요."
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.dismissToast)
                }
                
            case .createInviteCode:
                return createInviteCode()
                
            case let .createInviteCodeResponse(.success(code)):
                state.inviteCode = code.code
                buildAndCopy(friendCode: code.code)
                state.showToast = true
                state.toastMessage = "친구 추가 링크를 복사했어요."
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.dismissToast)
                }
                
            case let .createInviteCodeResponse(.failure(error)):
                state.showToast = true
                state.toastMessage = "링크 생성에 실패했어요."
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.dismissToast)
                }
                
            case .dismissToast:
                state.showToast = false
                return .none
                
            case .friendCard:
                return .none
            }
        }
        .ifLet(\.$friendCard, action: \.friendCard) {
            FriendCardReducer()
        }
    }
}

extension FriendsViewReducer {
    func loadFriendsList() -> Effect<Action> {
        return .run { send in
            await send(.friendsListResponse(
                await repository.getFriendList()
            ))
        }
    }
    
    func deleteFriend(id: String) -> Effect<Action> {
        return .run { send in
            let result = await repository.deleteFriend(id)
            await send(.deleteFriendResponse(id: id, result))
        }
    }
    
    func createInviteCode() -> Effect<Action> {
        return .run { send in
            let result = await repository.createInviteCode()
            await send(.createInviteCodeResponse(result))
        }
    }
    
    func buildAndCopy(friendCode: String) {
        Task {
            guard let url = await linkBuilder.makeInviteURL(friendCode: friendCode) else { return }
            Clipboard.copy(
"""
'딴딴'에서 운동하면서 펫 키워요!
혼자보다 같이 하면 더 꾸준해지고, 펫도 더 건강해져요 🐾
우리 같이 운동하고 서로 응원해요 💪

\(url)
"""
            )
        }
    }
}
