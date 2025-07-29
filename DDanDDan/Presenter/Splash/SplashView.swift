//
//  SplashView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/19/24.
//

import SwiftUI

struct SplashView: View {
    @StateObject var viewModel: SplashViewModel
    @State private var showUpdateAlert = false
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
                .ignoresSafeArea(.all)
            VStack(alignment: .center) {
                Spacer()
                Image(.splashLogo)
                Spacer()
                Image(.splashStart)
            }
        }
        .alert("업데이트 필요", isPresented: $showUpdateAlert) {
            Button("업데이트") {
                if let url = viewModel.getAppStoreURL() {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("새로운 버전이 출시되었습니다. 업데이트해주세요.")
        }
        .onAppear {
            if viewModel.checkForceUpdate() {
                showUpdateAlert = true
            } else {
                viewModel.navigateToNextScreen()
            }
        }
    }
}
