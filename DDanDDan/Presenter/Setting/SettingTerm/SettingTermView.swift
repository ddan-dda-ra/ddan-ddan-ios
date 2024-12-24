//
//  SettingTermView.swift
//  DDanDDan
//
//  Created by hwikang on 10/7/24.
//

import SwiftUI

enum SettingTerm: CaseIterable {
    case service
    case privacy
    
    var description: String {
        switch self {
        case .privacy: "개인정보 처리방침"
        case .service: "서비스 이용약관"
        }
    }
    
    var urlString: String {
        switch self {
        case .privacy: "https://www.notion.so/1d544c615c44412fa51d2ecb9f98116a"
        case .service: "https://www.notion.so/4105267fc3b849fba10b8a3155809255"
        }
    }
    
}
struct SettingTermView: View {
    @ObservedObject public var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Color.backgroundBlack.edgesIgnoringSafeArea(.all)
            VStack {
                CustomNavigationBar(
                    title: "약관 및 개인정보 처리 동의",
                    leftButtonImage: Image(.arrow),
                    leftButtonAction: {
                        coordinator.pop()
                    }
                )
                List(SettingTerm.allCases, id: \.self) { item in
                    NavigationLink(destination: WebView(url: item.urlString)) {
                        Text(item.description)
                    }
                    .foregroundStyle(Color.textHeadlinePrimary)
                    .listRowBackground(Color.backgroundBlack)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SettingTermView(coordinator: .init())
}
