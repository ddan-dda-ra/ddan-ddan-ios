//
//  NavigationBarView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/21/24.
//

import SwiftUI

struct CustomNavigationBar: View {
    var title: String
    var leftButtonImage: Image?
    var leftButtonAction: (() -> Void)? = nil
    var rightButtonImage: Image?
    var rightButtonAction: (() -> Void)? = nil
    var buttonSize: Int
    var navigationBarHeight: CGFloat
    
    init(
        title: String = "",
        leftButtonImage: Image? = nil,
        leftButtonAction: (() -> Void)? = nil,
        rightButtonImage: Image? = nil,
        rightButtonAction: (() -> Void)? = nil,
        buttonSize: Int = 24,
        navigationBarHeight: CGFloat = 48
    ) {
        self.title = title
        self.leftButtonImage = leftButtonImage
        self.leftButtonAction = leftButtonAction
        self.rightButtonImage = rightButtonImage
        self.rightButtonAction = rightButtonAction
        self.buttonSize = buttonSize
        self.navigationBarHeight = navigationBarHeight
    }
    
    var body: some View {
        ZStack {
            Color.backgroundBlack
                .ignoresSafeArea(edges: [.top, .horizontal])
            
            HStack {
                if let leftButtonImage = leftButtonImage,
                   let leftButtonAction = leftButtonAction {
                    Button(action: leftButtonAction) {
                        leftButtonImage
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: buttonSize.adjusted, height: buttonSize.adjusted)
                } else {
                    Spacer()
                        .frame(width: buttonSize.adjusted)
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let rightButtonImage = rightButtonImage,
                   let rightButtonAction = rightButtonAction {
                    Button(action: rightButtonAction) {
                        rightButtonImage
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: buttonSize.adjusted, height: buttonSize.adjusted)
                } else {
                    Spacer()
                        .frame(width: buttonSize.adjusted)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: navigationBarHeight)
    }
}
