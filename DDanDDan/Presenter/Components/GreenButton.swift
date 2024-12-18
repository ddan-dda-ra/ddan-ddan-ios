//
//  GreenButton.swift
//  DDanDDan
//
//  Created by hwikang on 8/17/24.
//

import SwiftUI

struct GreenButton: View {
    public let disabled: Bool
    private let action: () -> Void, title: String
    private let greenColor = Color(red: 19/255, green: 230/255, blue: 149/255)
    private let greyColor = Color(red: 41/255, green: 41/255, blue: 41/255)
    init(action: @escaping () -> Void, title: String, disabled: Bool) {
        self.action = action
        self.title = title
        self.disabled = disabled
    }
    var body: some View {
        Button {
            if !disabled {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: 60)
                .background(disabled ? greyColor : greenColor)
                .foregroundColor(disabled ? .gray : .black)
        }.padding(.bottom, 1)
            .disabled(disabled)
    }
}

