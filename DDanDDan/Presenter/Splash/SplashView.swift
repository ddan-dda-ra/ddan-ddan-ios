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
            Text(viewModel.updateAlertMessage)
        }
        .task {
            if await viewModel.checkForceUpdate() {
                showUpdateAlert = true
            } else {
                viewModel.navigateToNextScreen()
            }
        }
    }
}
