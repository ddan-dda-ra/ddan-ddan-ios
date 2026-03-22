//
//  DialogView.swift
//  DDanDDan
//
//  Created by hwikang on 7/21/24.
//

import SwiftUI

struct DialogView: View {
    @Binding public var show: Bool
    public let title: String, description: String, rightButtonTitle: String, leftButtonTitle: String
    var leftButtonHandler: (() -> Void)?
    var rightButtonHandler: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center) {
                Text(title)
                    .font(.heading6_semibold16)
                    .foregroundStyle(Color.textHeadlinePrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                if !description.isEmpty {
                    Text(description)
                        .font(.body2_regular14)
                        .foregroundStyle(Color.textBodyTeritary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 3)
                }
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            show.toggle()
                            leftButtonHandler?()
                        }
                    } label: {
                        Text(leftButtonTitle)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(Color.buttonAlternative)
                            .foregroundColor(.textButtonAlternative)
                            .font(.heading6_semibold16)
                            .cornerRadius(4)
                    }
                    Button {
                        withAnimation {
                            show.toggle()
                            rightButtonHandler?()
                        }
                    } label: {
                        Text(rightButtonTitle)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .font(.heading6_semibold16)
                            .background(Color.buttonGreen)
                            .foregroundColor(.textButtonPrimaryDefault)
                            .cornerRadius(4)
                    }
                }
                .padding(EdgeInsets(top: 28, leading: 20, bottom: 20, trailing: 20))
            }
            .background(Color(red: 33/255, green: 33/255, blue: 33/255))
            .cornerRadius(8)
            .shadow(radius: 20)
            .frame(width: 300)
        }
    }
}

//#Preview {
//    DialogView(show: $true, title: "title", description: "description", rightButtonTitle: "OK", leftButtonTitle: "Cancel")
//}
