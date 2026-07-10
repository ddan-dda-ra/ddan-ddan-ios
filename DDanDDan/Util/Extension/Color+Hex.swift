//
//  Color+Hex.swift
//  DDanDDan
//
//  Created by ddingmin on 2026/05/16.
//

import SwiftUI

extension Color {
    /// 16진수 문자열로부터 Color 생성.
    /// - Parameter hex: `#RRGGBB`, `RRGGBB`, `#RRGGBBAA`, `RRGGBBAA` 형식 지원.
    ///   잘못된 입력 시 검정색을 반환한다.
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgba: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&rgba),
              trimmed.count == 6 || trimmed.count == 8 else {
            self = .black
            return
        }
        let r, g, b, a: Double
        if trimmed.count == 6 {
            r = Double((rgba & 0xFF0000) >> 16) / 255.0
            g = Double((rgba & 0x00FF00) >> 8) / 255.0
            b = Double(rgba & 0x0000FF) / 255.0
            a = 1.0
        } else {
            r = Double((rgba & 0xFF000000) >> 24) / 255.0
            g = Double((rgba & 0x00FF0000) >> 16) / 255.0
            b = Double((rgba & 0x0000FF00) >> 8) / 255.0
            a = Double(rgba & 0x000000FF) / 255.0
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
