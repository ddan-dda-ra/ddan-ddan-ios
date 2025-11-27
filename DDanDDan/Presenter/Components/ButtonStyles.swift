//
//  ButtonStyles.swift
//  DDanDDan
//
//  Created by 이지희 on 9/5/25.
//

import SwiftUI


struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.heading6_semibold16)
            .padding(.vertical, 17)
            .frame(minWidth: 130, maxWidth: 136, maxHeight: 56)
            .background(.buttonDefault)
            .foregroundColor(.backgroundGray)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.heading6_semibold16)
            .padding(.vertical, 17)
            .frame(minWidth: 130, maxWidth: 136, maxHeight: 56)
            .background(.buttonAlternative)
            .foregroundColor(.buttonDefault)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
