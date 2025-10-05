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
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case friendsListResponse(Result<FriendList, NetworkError>)
        case myProfileLoaded(ProfileModel)
        
        // 삭제 관련 액션
        case showDeleteAlert(id: String)
        case confirmDelete
        case deleteFriendResponse(id: String, Result<EmptyEntity, NetworkError>)
        
        case createInviteCode
        case createInviteCodeResponse(Result<InviteCode, NetworkError>)
        case dismissToast
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                return loadFriendsList()
                
            case let .friendsListResponse(.success(friendsList)):
                state.isLoading = false
                state.friendsList = friendsList.friends
                state.errorMessage = nil
                return .none
                
            case let .friendsListResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .myProfileLoaded(profile):
                state.myProfilePet = profile
                return .none
                
            case let .showDeleteAlert(id):
                state.friendToDelete = id
                state.deleteFriendAlert = true
                return .none
                
            case .confirmDelete:
                guard let friendId = state.friendToDelete else { return .none }
                state.deleteFriendAlert = false
                state.friendToDelete = nil  // 삭제 요청 후 초기화
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
                state.errorMessage = error.localizedDescription
                return .none
                
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
                state.errorMessage = error.localizedDescription
                return .none
                
            case .dismissToast:
                state.showToast = false
                return .none
            }
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
            print("생성된 url : \(url)")
            Clipboard.copy(url)
        }
    }
}
