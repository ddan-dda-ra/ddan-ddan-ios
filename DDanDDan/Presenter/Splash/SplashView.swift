//
//  SplashView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/19/24.
//

import SwiftUI

struct SplashView: View {
    @StateObject var viewModel: SplashViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showUpdateAlert = false
    @State private var needsForceUpdate = false

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
                needsForceUpdate = true
                showUpdateAlert = true
            } else {
                viewModel.navigateToNextScreen()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active, needsForceUpdate {
                Task {
                    if await viewModel.checkForceUpdate() {
                        showUpdateAlert = true
                    } else {
                        needsForceUpdate = false
                        viewModel.navigateToNextScreen()
                    }
                }
            }
        }
    }
}
