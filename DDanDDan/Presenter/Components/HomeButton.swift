//
//  HomeButton.swift
//  DDanDDan
//
//  Created by 이지희 on 10/25/24.
//

import SwiftUI

struct HomeButton: View {
    private let buttonTitle: String
    private let count: Int
    private let image: ImageResource
    init(buttonTitle: String, count: Int, image: ImageResource) {
        self.buttonTitle = buttonTitle
        self.count = count
        self.image = image
    }
    
    var body: some View {
        ZStack {
            Image(.feedButtonFrame)
                .resizable()
                .scaledToFill()
            VStack {
                Image(image)
                HStack {
                    Text(buttonTitle)
                        .font(.neoDunggeunmo16)
                        .foregroundStyle(.white)
                    Text("x")
                        .font(.neoDunggeunmo16)
                        .foregroundStyle(.textBodyTeritary)
                    Text("\(count)")
                        .font(.neoDunggeunmo16)
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12.adjusted)
            .padding(.horizontal, 10.adjusted)
        }
        
    }
}
