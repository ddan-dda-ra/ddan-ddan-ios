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
    let appCoordinator: AppCoordinator
    
    @Published var toastMessage: String = "로그인에 실패했습니다."
    @Published var showToast: Bool = false
    @Published private(set) var bootstrapState: AuthenticatedBootstrapState = .idle

    var isLoading: Bool { bootstrapState == .loading }
    
    init(
        repository: LoginRepositoryProtocol,
        appCoordinator: AppCoordinator,
        catalogRepository: any PetCatalogRepositoryProtocol = PetCatalogRepository.shared,
        homeRepository: HomeRepositoryProtocol = HomeRepository()
    ) {
        self.repository = repository
        self.appCoordinator = appCoordinator
        self.catalogRepository = catalogRepository
        self.homeRepository = homeRepository
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
                    guard case let .success(mainPet) = await homeRepository.getMainPetInfo() else {
                        await failLogin(message: "메인 펫 정보를 확인하지 못했어요. 다시 시도해 주세요.")
                        return
                    }
                    let bootstrap = await catalogRepository.prepareForMain(
                        petType: mainPet.mainPet.type,
                        level: mainPet.mainPet.level
                    )
                    guard case .success = bootstrap else {
                        await failLogin(message: "펫 데이터를 준비하지 못했어요. 다시 시도해 주세요.")
                        return
                    }
                    await MainActor.run { [weak self] in
                        self?.appCoordinator.petInfo = mainPet
                        UserDefaultValue.petType = mainPet.mainPet.type
                        UserDefaultValue.petId = mainPet.mainPet.id
                        UserDefaultValue.level = mainPet.mainPet.level
                    }
                } else {
                    await catalogRepository.startAuthenticatedRefresh()
                }
                await MainActor.run { [weak self] in
                    self?.bootstrapState = .idle
                    self?.appCoordinator.triggerHomeUpdate(trigger: true)
                    if loginData.isOnboardingComplete {
                        self?.appCoordinator.setRoot(to: .mainTab)
                    } else {
                        self?.appCoordinator.setRoot(to: .signUp)
                    }
                }
            case .failure(let error):
                await MainActor.run { [weak self] in
                    switch error {
                    case .serverError(_, let message):
                        self?.toastMessage = "오류가 발생했습니다.: \(message)"
                    case .dataNil, .encodingError, .failToDecode, .invalidResponse, .requestFailed, .urlError:
                        break
                    }
                    self?.showToastMessage()
                    self?.bootstrapState = .failed(self?.toastMessage ?? "로그인에 실패했습니다.")
                }
                print(error)
                
            }
        }
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
        if tokenType == "KAKAO" {
            UserManager.shared.kakaoToken = token
        } else if tokenType == "APPLE" {
            UserManager.shared.appleToken = token
        }
    }
    
    private func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hideToastMessage()
        }
    }
    
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
