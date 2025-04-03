//
//  CustomScrollView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/31/25.
//

import SwiftUI

struct CustomScrollView<Content: View>: View {
    @Binding private var contentOffset: CGPoint
    @Binding private var reachToBottom: Bool
    
    private let frameHeight: CGFloat
    @State private var contentHeight = CGFloat.zero
    @Namespace private var coordinateSpaceName: Namespace.ID
    @ViewBuilder private var content: (ScrollViewProxy) -> Content
    
    init(
        frameHeight: CGFloat,
        contentOffset: Binding<CGPoint>,
        reachToBottom: Binding<Bool>,
        @ViewBuilder content: @escaping (ScrollViewProxy) -> Content
    ) {
        self.frameHeight = frameHeight
        _contentOffset = contentOffset
        _reachToBottom = reachToBottom
        self.content = content
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            ScrollViewReader { scrollViewProxy in
                content(scrollViewProxy)
                    .background {
                        GeometryReader { geometryProxy in
                            Color.clear
                                .onAppear {
                                    let contentHeight = geometryProxy.size.height
                                    self.contentHeight = contentHeight
                                }
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: CGPoint(
                                        x: -geometryProxy.frame(in: .named(coordinateSpaceName)).minX,
                                        y: -geometryProxy.frame(in: .named(coordinateSpaceName)).minY
                                    )
                                )
                        }
                    }
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            guard contentHeight != 0 else { return }
            let currentScrollOffset = value.y + frameHeight
            reachToBottom = contentHeight <= currentScrollOffset
            contentOffset = value
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint { .zero }
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
