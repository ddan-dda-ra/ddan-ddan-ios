//
//  ImageDialogView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/8/24.
//

import SwiftUI

struct ImageDialogView: View {
    @Binding public var show: Bool
    public let image: ImageResource, title: String, description: String, buttonTitle: String
    var buttonHandler: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                    .frame(height: 40)
                VStack(alignment: .center) {
                    Image(image)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.bottom, 24)
                    Text(title)
                        .font(.heading6_semibold16)
                        .foregroundStyle(Color.textHeadlinePrimary)
                        .padding(.bottom, 4)
                    Text(description)
                        .font(.subTitle1_semibold14)
                        .foregroundStyle(Color.textBodyTeritary)
                }
                Button {
                    withAnimation {
                        show.toggle()
                        buttonHandler?()
                    }
                } label: {
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .font(.heading6_semibold16)
                        .background(Color.buttonGreen)
                        .foregroundColor(.black)
                        .padding(20)
                }
            }
            .frame(width: 308, height: 278)
            .background(Color.backgroundGray)
            .cornerRadius(8)
            .shadow(radius: 20)
        }
        .background(Color.clear.opacity(0))
    }
}
