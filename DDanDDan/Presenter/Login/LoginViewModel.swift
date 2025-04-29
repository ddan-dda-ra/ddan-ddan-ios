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
    let appCoordinator: AppCoordinator
    
    @Published var toastMessage: String = "로그인에 실패했습니다."
    @Published var showToast: Bool = false
    
    init(repository: LoginRepositoryProtocol, appCoordinator: AppCoordinator) {
        self.repository = repository
        self.appCoordinator = appCoordinator
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
        
        Task {
            await saveToken(token: token, tokenType: tokenType)
            let result = await repository.login(token: token, tokenType: tokenType)
            switch result {
            case .success(let loginData):
                await UserManager.shared.login(loginData: loginData)
                DispatchQueue.main.async { [weak self] in
                    self?.appCoordinator.triggerHomeUpdate(trigger: true)
                    if loginData.isOnboardingComplete {
                        self?.appCoordinator.setRoot(to: .home)
                    } else {
                        self?.appCoordinator.setRoot(to: .signUp)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    switch error {
                    case .serverError(_, let message):
                        self?.toastMessage = "오류가 발생했습니다.: \(message)"
                    case .dataNil, .encodingError, .failToDecode, .invalidResponse, .requestFailed, .urlError:
                        break
                    }
                    self?.showToastMessage()
                }
                print(error)
                
            }
        }
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
