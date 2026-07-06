//
//  SignUpViewModel.swift
//  DDanDDan
//
//  Created by hwikang on 10/23/24.
//
import Foundation
import AuthenticationServices
import KakaoSDKUser
import KakaoSDKCommon

public class LoginViewModel: NSObject, ObservableObject {
    private let repository: LoginRepositoryProtocol
    private let catalogRepository: any PetCatalogRepositoryProtocol
    private let homeRepository: HomeRepositoryProtocol
    private let watchSyncer: any WatchPetSyncing
    let appCoordinator: AppCoordinator
    
    @Published var toastMessage: String = "로그인에 실패했습니다."
    @Published var showToast: Bool = false
    @Published private(set) var bootstrapState: AuthenticatedBootstrapState = .idle

    var isLoading: Bool { bootstrapState == .loading }
    
    init(
        repository: LoginRepositoryProtocol,
        appCoordinator: AppCoordinator,
        catalogRepository: any PetCatalogRepositoryProtocol = PetCatalogRepository.shared,
        homeRepository: HomeRepositoryProtocol = HomeRepository(),
        watchSyncer: any WatchPetSyncing = WatchConnectivityManager.shared
    ) {
        self.repository = repository
        self.appCoordinator = appCoordinator
        self.catalogRepository = catalogRepository
        self.homeRepository = homeRepository
        self.watchSyncer = watchSyncer
    }
    
    func appleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func kakaoLogin() {
        if UserApi.isKakaoTalkLoginAvailable() {
            print("=== 카카오톡으로 로그인 가능 ===")
            UserApi.shared.loginWithKakaoTalk(serviceTerms: []) { [weak self] token, error in
                if let error = error {
                    print(error)
                    return
                }
                self?.login(token: token?.accessToken, tokenType: "KAKAO")
            }
        } else {
            print("=== 카카오 계정으로 로그인 가능 ===")
            UserApi.shared.loginWithKakaoAccount(serviceTerms: []) { [weak self] token, error in
                if let error = error {
                    print(error)
                    return
                }
                self?.login(token: token?.accessToken, tokenType: "KAKAO")
            }
        }
    }
    
    private func login(token: String?, tokenType: String) {
        guard let token = token else { return }
        
        Task { [weak self] in
            guard let self, await self.beginLogin() else { return }
            await saveToken(token: token, tokenType: tokenType)
            let result = await repository.login(token: token, tokenType: tokenType)
            switch result {
            case .success(let loginData):
                await UserManager.shared.login(loginData: loginData)
                if loginData.isOnboardingComplete {
                    guard await bootstrapCompletedUser() else { return }
                    return
                } else {
                    await catalogRepository.startAuthenticatedRefresh()
                }
                await routeToSignUp()
            case .failure(let error):
                await handleLoginFailure(error)
                print(error)
                
            }
        }
    }

    @MainActor
    private func routeToSignUp() {
        bootstrapState = .idle
        appCoordinator.setRoot(to: .signUp)
    }

    @MainActor
    private func handleLoginFailure(_ error: NetworkError) {
        if case let .serverError(_, message) = error {
            toastMessage = "오류가 발생했습니다.: \(message)"
        }
        showToastMessage()
        bootstrapState = .failed(toastMessage)
    }

    @MainActor
    func bootstrapCompletedUser() async -> Bool {
        bootstrapState = .loading
        async let userInfoResult = homeRepository.getUserInfo()
        async let mainPetResult = homeRepository.getMainPetInfo()
        guard case let .success(userInfo) = await userInfoResult,
              case let .success(mainPet) = await mainPetResult else {
            failLogin(message: "사용자와 메인 펫 정보를 확인하지 못했어요. 다시 시도해 주세요.")
            return false
        }
        let bootstrap = await catalogRepository.prepareForMain(
            petType: mainPet.mainPet.type,
            level: mainPet.mainPet.level
        )
        guard case let .success(snapshot) = bootstrap else {
            failLogin(message: "펫 데이터를 준비하지 못했어요. 다시 시도해 주세요.")
            return false
        }
        let presentation = PetPresentation.resolve(
            petType: mainPet.mainPet.type,
            petLevel: mainPet.mainPet.level,
            snapshot: snapshot
        )
        guard presentation.level?.assetURLs.count == 3 else {
            failLogin(message: "메인 펫 데이터를 찾을 수 없어요. 다시 시도해 주세요.")
            return false
        }
        await watchSyncer.syncPet(
            purposeKcal: userInfo.purposeCalorie,
            petType: mainPet.mainPet.type,
            level: mainPet.mainPet.level,
            presentation: presentation
        )
        UserDefaultValue.petType = mainPet.mainPet.type
        UserDefaultValue.petId = mainPet.mainPet.id
        UserDefaultValue.level = mainPet.mainPet.level
        UserDefaultValue.userId = userInfo.id
        UserDefaultValue.purposeKcal = userInfo.purposeCalorie
        appCoordinator.commitAuthenticatedBootstrap(userInfo: userInfo, petInfo: mainPet)
        bootstrapState = .idle
        return true
    }

    @MainActor
    private func beginLogin() -> Bool {
        guard bootstrapState != .loading else { return false }
        bootstrapState = .loading
        return true
    }

    @MainActor
    private func failLogin(message: String) {
        toastMessage = message
        bootstrapState = .failed(message)
        showToastMessage()
    }
    
    @MainActor
    private func saveToken(token: String, tokenType: String) {
        UserManager.shared.loginCredential = .init(token: token, tokenType: tokenType)
        if tokenType == "KAKAO" {
            UserManager.shared.kakaoToken = token
            UserManager.shared.appleToken = nil
        } else if tokenType == "APPLE" {
            UserManager.shared.appleToken = token
            UserManager.shared.kakaoToken = nil
        }
    }
    
    @MainActor
    private func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hideToastMessage()
        }
    }
    
    @MainActor
    private func hideToastMessage() {
        showToast = false
    }
    
}

// MARK: - ASAuthorizationControllerDelegate
extension LoginViewModel: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("Apple User ID: \(userID)")
            print("Apple Full Name: \(String(describing: fullName))")
            print("Apple Email: \(String(describing: email))")
            
            if let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {
                login(token: tokenString, tokenType: "APPLE")
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Login Failed: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension LoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}
