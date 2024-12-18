//
//  SignUpView.swift
//  DDanDDan
//
//  Created by hwikang on 7/21/24.
//

import SwiftUI
import KakaoSDKUser
import KakaoSDKCommon

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    var body: some View {
            ZStack {
                Color.backgroundBlack.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Image(.splashLogo)
                        .resizable()
                        .frame(width: 145, height: 165)
                    Spacer()
                    
                    Button {
                        viewModel.kakaoLogin()
                    } label: {
                        Text("카카오톡으로 시작하기")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            .background(Color(red: 254/255, green: 229/255, blue: 0/255))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 9)
                    Button {
                        viewModel.appleLogin()
                        
                    } label: {
                        Text("Apple로 계속하기")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            .background(.black)
                            .foregroundColor(.white)
                            .border(.white, width: 1)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
                TransparentOverlayView(isPresented: viewModel.showToast) {
                    VStack {
                        ToastView(message: viewModel.toastMessage)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: viewModel.showToast)
                    .position(x: UIScreen.main.bounds.width / 2 + 10, y: UIScreen.main.bounds.height - 250)
                }
            }
    }
    
}

#Preview {
    LoginView(viewModel: LoginViewModel(repository: LoginRepository(), appCoordinator: .init()))
}
