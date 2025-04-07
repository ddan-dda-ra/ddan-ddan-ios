//
//  CustomScrollView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/31/25.
//

import SwiftUI

struct CustomScrollView<Content: View>: View {
    let content: () -> Content
    let onBottomReached: () -> Void

    @State private var isBottomReached = false
    @State private var hasScrolled = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { _ in
                    Color.clear
                        .onAppear {
                            // 토스트가 바로 뜨지 않도록 딜레이
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                hasScrolled = true
                            }
                        }
                }
                .frame(height: 0)

                content()

                Color.clear
                    .frame(height: 1)
                    .modifier(ScrollOffsetReader())
            }
            .padding()
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(OffsetPreferenceKey.self) { maxY in
            let screenHeight = UIScreen.main.bounds.height

            if hasScrolled && maxY < screenHeight + 50 && !isBottomReached {
                isBottomReached = true
                onBottomReached()
            } else if maxY > screenHeight + 100 {
                isBottomReached = false
            }
        }
    }
}

struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetReader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: OffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).maxY
                        )
                }
                .frame(height: 1)
            )
    }
}
