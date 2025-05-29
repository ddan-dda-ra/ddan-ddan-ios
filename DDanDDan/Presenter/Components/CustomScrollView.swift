//
//  CustomScrollView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/31/25.
//

import SwiftUI

import ComposableArchitecture

struct CustomScrollView<Content: View>: View {
    let content: () -> Content
    let onBottomReached: () -> Void

    @State private var isBottomReached = false
    @State private var lastOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                WithPerceptionTracking {
                    content()
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                        .modifier(ScrollOffsetReader())
                }
            }
        }
        .scrollIndicators(.hidden)
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(OffsetPreferenceKey.self) { maxY in
            let screenHeight = UIScreen.main.bounds.height

            let isScrollingDown = maxY < lastOffset

            if maxY < screenHeight - 300, !isBottomReached, isScrollingDown {
                isBottomReached = true
                onBottomReached()
            } else if maxY > screenHeight + 100 {
                isBottomReached = false
            }

            lastOffset = maxY
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
                WithPerceptionTracking {
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: OffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).maxY
                            )
                    }
                    .frame(height: 1)
                }
            )
    }
}
