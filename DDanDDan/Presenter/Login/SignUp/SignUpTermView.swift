//
//  SignUpTermView.swift
//  DDanDDan
//
//  Created by hwikang on 7/29/24.
//

import SwiftUI
import Combine

public enum SignUpPath: Hashable {
    case term
    case egg
    case nickname
    case calorie
    case success
    case main
    case viewTerm(url:String)
}

public struct SignUpTermView<ViewModel: SignUpViewModelProtocol>: View {
    @State private var serviceTermAgree: Bool = false
    @State private var privacyTermAgree: Bool = false
    @State private var buttonDisabled: Bool = true
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var coordinator: AppCoordinator
    
    public var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        
                        Text("딴딴에 오신 것을 환영합니다")
                            .font(.neoDunggeunmo24)
                            .foregroundStyle(.white)
                        
                            .padding(.top, 80)
                        Text("서비스 시작 및 가입을 위해 먼저\n가입 및 정보 제공에 동의해 주세요.")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray)
                            .padding(.top, 8)
                        Button {
                            let isAllAgree = serviceTermAgree && privacyTermAgree
                            buttonDisabled = isAllAgree
                            serviceTermAgree = !isAllAgree
                            privacyTermAgree = !isAllAgree
                        } label: {
                            let image = serviceTermAgree && privacyTermAgree ? "checkboxCircleSelected" : "checkboxCircle"
                            Label("전체동의", image: image)
                                .foregroundColor(.gray)
                                .font(.system(size: 16, weight: .bold))
                        }
                        TermButton(title: "서비스 이용약관", imageName: serviceTermAgree ? "checkboxSelected" :"checkbox", pointTitle: "(필수)") {
                            serviceTermAgree.toggle()
                        } viewTerm: {
                            coordinator.push(to: .viewTerm(url: "https://www.notion.so/4105267fc3b849fba10b8a3155809255"))
                        }
                        .padding(.top, 12)
                        TermButton(title: "개인정보 처리방침", imageName:privacyTermAgree ? "checkboxSelected" :"checkbox", pointTitle: "(필수)") {
                            privacyTermAgree.toggle()
                        }viewTerm: {
                            coordinator.push(to: .viewTerm(url: "https://www.notion.so/1d544c615c44412fa51d2ecb9f98116a"))
                        }
                        .padding(.top, 12)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    GreenButton(action: {
                        coordinator.push(to: .nickname)
                    }, title: "시작하기", disabled: buttonDisabled)
                    
                }
            } 
            .navigationDestination(for: SignUpPath.self) { path in
                switch path {
                case .term: SignUpTermView(viewModel: viewModel, coordinator: coordinator)
                case .egg: SignUpEggView(viewModel: viewModel, coordinator: coordinator)
                case .nickname: SignUpNicknameView(viewModel: viewModel, coordinator: coordinator)
                case .calorie: SignUpCalorieView(viewModel: viewModel, coordinator: coordinator)
                case .success: SignUpSuccessView(viewModel: viewModel, coordinator: coordinator)
                case .main: SettingView(coordinator: coordinator)
                case .viewTerm(url: let url):
                    WebView(url: url)
                }
            }
          
        }
       
    }
}

struct TermButton: View {
    private let title: String, imageName: String, pointTitle: String
    private let action: () -> Void
    private let viewTerm: () -> Void
    init(title: String, imageName: String, pointTitle: String, 
         action: @escaping () -> Void,
         viewTerm: @escaping () -> Void) {
        self.title = title
        self.imageName = imageName
        self.pointTitle = pointTitle
        self.action = action
        self.viewTerm = viewTerm
    }
    
    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Image(imageName)
                    Text("\(pointTitle) ")
                        .foregroundColor(Color(red: 19/255, green: 230/255, blue: 169/255))
                    + Text(title)
                        .foregroundColor(Color(red: 201/255, green: 201/255, blue: 201/255))
                        .font(.system(size: 16))
                    
                }
            }
            Spacer()
            Button(action: viewTerm) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
       
        
    }
}

#Preview {
    SignUpTermView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: AppCoordinator())
}

