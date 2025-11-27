//
//  ToolKitView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import SwiftUI

struct TooltipView: View {
    var textString: String = ""
    var alignment: HorizontalAlignment
    
    init(textString: String, alignment: HorizontalAlignment = .center) {
        self.textString = textString
        self.alignment = alignment
    }
    
    var body: some View {
        VStack(alignment: self.alignment) {
            Triangle()
                .foregroundStyle(.borderGray)
                .frame(width: 22, height: 16)
                .padding(.leading, self.alignment == .leading ? 12 : 0)
            Text(self.textString)
                .font(.subTitle1_semibold14)
                .lineLimit(3)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.textHeadlinePrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color.borderGray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: -17)
        }
    }
}


struct Triangle: Shape {
    var cornerRadius: CGFloat = 4.0

       func path(in rect: CGRect) -> Path {
           let width = rect.width
           let height = rect.height
           
           let radius = cornerRadius // 너무 크면 깨지므로 제한

           let top = CGPoint(x: rect.midX, y: rect.minY)
           let bottomLeft = CGPoint(
               x: rect.midX - width * 0.5 * cos(.pi / 6),
               y: rect.maxY
           )
           let bottomRight = CGPoint(
               x: rect.midX + width * 0.5 * cos(.pi / 6),
               y: rect.maxY
           )

           func roundedCorner(from p1: CGPoint, corner: CGPoint, to p2: CGPoint) -> (start: CGPoint, end: CGPoint, control: CGPoint) {
               let dir1 = CGVector(dx: corner.x - p1.x, dy: corner.y - p1.y)
               let dir2 = CGVector(dx: corner.x - p2.x, dy: corner.y - p2.y)

               let len1 = sqrt(dir1.dx * dir1.dx + dir1.dy * dir1.dy)
               let len2 = sqrt(dir2.dx * dir2.dx + dir2.dy * dir2.dy)

               let start = CGPoint(x: corner.x - dir1.dx / len1 * radius,
                                   y: corner.y - dir1.dy / len1 * radius)
               let end = CGPoint(x: corner.x - dir2.dx / len2 * radius,
                                 y: corner.y - dir2.dy / len2 * radius)

               return (start, end, corner)
           }

           let corner1 = roundedCorner(from: bottomRight, corner: top, to: bottomLeft)
           let corner2 = roundedCorner(from: top, corner: bottomLeft, to: bottomRight)
           let corner3 = roundedCorner(from: bottomLeft, corner: bottomRight, to: top)

           var path = Path()
           path.move(to: corner1.start)
           path.addQuadCurve(to: corner1.end, control: corner1.control)
           path.addLine(to: corner2.start)
           path.addQuadCurve(to: corner2.end, control: corner2.control)
           path.addLine(to: corner3.start)
           path.addQuadCurve(to: corner3.end, control: corner3.control)
           path.closeSubpath()

           return path
       }
   }


#Preview {
    TooltipView(textString: "한 달 동안 목표한 칼로리를\n누적 달성한 순서에요", alignment: .leading)
}
