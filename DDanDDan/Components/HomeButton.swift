//
//  HomeButton.swift
//  DDanDDan
//
//  Created by 이지희 on 9/26/24.
//

import SwiftUI

struct HomeButton: View {
  private let buttonTitle: String
  private let count: Int
  
  init(buttonTitle: String, count: Int) {
    self.buttonTitle = buttonTitle
    self.count = count
  }
  
  var body: some View {
    ZStack {
      Color(.backgorundGray)
        .cornerRadius(8)
      VStack {
        Text(buttonTitle)
          .font(.heading6_semibold16)
          .foregroundStyle(.white)
        Text("\(count)개 보유")
          .font(.body3_regular12)
          .foregroundStyle(.textBodyTeritary)
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 43)
    }
    .border(.borderGray, width: 2)
    .cornerRadius(8)
  }
}

//#Preview {
//    HomeButton()
//}
