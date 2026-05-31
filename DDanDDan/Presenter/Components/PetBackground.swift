//
//  PetBackground.swift
//  DDanDDan
//
//  Created by ddingmin on 2026/05/16.
//

import SwiftUI
import SVGView

/// 펫 배경이 렌더링되는 표면(컨텍스트).
/// 각 case는 렌더에 사용할 SVG 리소스를 결정한다.
enum BackgroundSurface {
    /// HomeView 일반 디바이스 (254×370 다이아 영역)
    case home
    /// HomeView SE 디바이스 (208×278 다이아, .fill로 채움)
    case homeCompact
    /// FriendCard 296×200 직사각형
    case friendCard

    /// 번들에 등록된 SVG 파일명(확장자 제외).
    var svgResourceName: String {
        switch self {
        case .home:        return "bg_diamond"
        case .homeCompact: return "bg_diamond_sm"
        case .friendCard:  return "bg_rectangle"
        }
    }
}

/// 펫 배경 뷰.
/// 번들 SVG의 형태 fill 색(`#FD85FF`)을 `pet.colorHex`로 런타임 치환한 뒤 `SVGView`로 렌더한다.
/// SVG에 sprinkle·그림자(ellipse)가 내장되어 별도 레이어가 필요 없다.
/// 번들 로드/치환 실패 시 `pet.color` 단색으로 폴백하여 크래시를 방지한다.
/// 호출처에서 외부 `.frame(...)`을 적용하거나, 부모 컨테이너의 자연스러운 크기를 따른다.
struct PetBackground: View {
    /// SVG 내 형태 fill의 원본 토큰. 모든 배경 SVG에서 동일하게 사용한다.
    private static let templateColorToken = "#FD85FF"

    let pet: PetType
    let surface: BackgroundSurface

    var body: some View {
        Group {
            if let svgString = makeColoredSVGString() {
                SVGView(string: svgString)
                    .scaledToFill()
                    .allowsHitTesting(false)
            } else {
                // 폴백: 번들 누락/디코딩 실패 시 펫 베이스 색 단색 표시
                pet.color
            }
        }
        .clipped()
    }

    /// 번들 SVG 텍스트를 로드하고 형태 fill 색을 펫 색으로 치환한다.
    /// 로드/디코딩 실패 시 `nil`을 반환하여 폴백을 유도한다.
    private func makeColoredSVGString() -> String? {
        guard let url = Bundle.main.url(
            forResource: surface.svgResourceName,
            withExtension: "svg"
        ), let rawSVG = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        // `#FD85FF`는 SVG 내 형태 fill에만 등장(white/#050000/none과 비충돌, 대문자 단일).
        return rawSVG.replacingOccurrences(
            of: Self.templateColorToken,
            with: pet.colorHex
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        PetBackground(pet: .pinkCat, surface: .home)
            .frame(width: 254, height: 370)
        PetBackground(pet: .greenHam, surface: .friendCard)
            .frame(width: 296, height: 200)
    }
    .padding()
    .background(Color.black)
}
