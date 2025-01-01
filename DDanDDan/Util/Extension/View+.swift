//
//  View+.swift
//  DDanDDan
//
//  Created by 이지희 on 11/8/24.
//

import UIKit
import SwiftUI

extension View {
    func transparentFullScreenCover<Content: View>(isPresented: Binding<Bool>, content: @escaping () -> Content) -> some View {
        fullScreenCover(isPresented: isPresented) {
            ZStack {
                content()
            }
            .background(TransparentBackground())
        }
    }
}

extension UIScreen {
    static var isSESizeDevice: Bool {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        return (width == 320 && height == 568) || (width == 375 && height == 667)
    }
}

struct TransparentOverlayView<Content: View>: View {
    let isPresented: Bool
    var isDimView: Bool
    let content: Content
    
    init(
        isPresented: Bool,
        isDimView: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.isPresented = isPresented
        self.isDimView = isDimView
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                content
                    .background( isDimView ? Color.black.opacity(0.5) : Color.clear)
                    .transition(.identity)
            }
        }
        .animation(nil, value: isPresented)
    }
}

struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
