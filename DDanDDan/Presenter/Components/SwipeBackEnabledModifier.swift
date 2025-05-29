//
//  SwipeBackEnabledModifier.swift
//  DDanDDan
//
//  Created by 이지희 on 5/27/25.
//

import SwiftUI

struct SwipeBackEnabledModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(EnableSwipeBackView())
    }
}

struct EnableSwipeBackView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            if let navigationController = controller.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = nil // 스와이프 충돌 방지
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

extension View {
    func swipeBackEnabled() -> some View {
        self.modifier(SwipeBackEnabledModifier())
    }
}
