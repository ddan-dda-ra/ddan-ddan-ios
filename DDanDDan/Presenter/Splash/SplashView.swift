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
    @State private var isCheckingUpdate = false

    var body: some View {
        ZStack {
            Color(.backgroundBlack)
                .ignoresSafeArea(.all)
            VStack(alignment: .center) {
                Spacer()
                Image(.splashLogo)
                Spacer()
                Image(.splashStart)
                if case let .failed(message) = viewModel.bootstrapState {
                    Text(message)
                        .font(.body2_regular14)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                    GreenButton(
                        action: { Task { await viewModel.retryInitialSetup() } },
                        title: "다시 시도",
                        disabled: false
                    )
                    .padding(.horizontal, 20)
                }
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
            if newPhase == .active, needsForceUpdate, !isCheckingUpdate {
                isCheckingUpdate = true
                Task {
                    if await viewModel.checkForceUpdate() {
                        showUpdateAlert = true
                    } else {
                        needsForceUpdate = false
                        viewModel.navigateToNextScreen()
                    }
                    isCheckingUpdate = false
                }
            }
        }
    }
}
