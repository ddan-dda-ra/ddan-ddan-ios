//
//  SignUpView.swift
//  DDanDDan
//
//  Created by paytalab on 7/21/24.
//

import SwiftUI
import KakaoSDKUser
import KakaoSDKCommon

struct SignUpView: View {
    @State private var showSignupTerm = false
    @State public var signUpData = SignUpData()
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 280, height: 280)
                    Spacer()
                    Button {
                        if UserApi.isKakaoTalkLoginAvailable() {
                            UserApi.shared.loginWithKakaoTalk(serviceTerms: []) { token, error in
                                getKakaoUser()
                            }
                        } else {
                            UserApi.shared.loginWithKakaoAccount(serviceTerms: []) { token, error in
                                getKakaoUser()
                            }
                        }
                        
                    } label: {
                        Text("카카오톡으로 시작하기")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            .background(Color(red: 254/255, green: 229/255, blue: 0/255))
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom)
                .navigationDestination(isPresented: $showSignupTerm) {
                    SignUpTermView(signUpData: signUpData)
                }
                
            }
        }
    }
    private func getKakaoUser() {
        UserApi.shared.me() { user, error in
            
            signUpData.kakaoUser = user
            showSignupTerm = true
        }
    }
}

#Preview {
    SignUpView()
}
