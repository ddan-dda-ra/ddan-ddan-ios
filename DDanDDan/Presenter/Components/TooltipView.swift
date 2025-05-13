//
//  ToolKitView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import SwiftUI

struct TooltipView: View {
    var textString: String = ""
    
    init(textString: String) {
        self.textString = textString
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Triangle()
                .foregroundStyle(.borderGray)
                .frame(width: 22, height: 18)
            Text(self.textString)
                .font(.subTitle1_semibold14)
                .lineLimit(3)  // 최대 3줄까지 허용
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.textHeadlinePrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.borderGray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: -18)
        }
    }
}


struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 3
        let midX = rect.midX
        let minY = rect.minY
        let maxY = rect.maxY
        let minX = rect.minX
        let maxX = rect.maxX
        
        var path = Path()
        
        path.move(to: CGPoint(x: midX, y: minY)) // 삼각형 꼭짓점
        
        path.addLine(to: CGPoint(x: minX + radius, y: maxY - radius))
        path.addQuadCurve(to: CGPoint(x: minX + radius * 2, y: maxY),
                          control: CGPoint(x: minX, y: maxY))
        
        path.addLine(to: CGPoint(x: maxX - radius * 2, y: maxY))
        path.addQuadCurve(to: CGPoint(x: maxX - radius, y: maxY - radius),
                          control: CGPoint(x: maxX, y: maxY))
        
        path.addLine(to: CGPoint(x: midX, y: minY)) // 다시 꼭짓점으로
        
        return path
    }
}
