//
//  PetImageView.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-13.
//

import SwiftUI
import Dependencies

/// `(PetType, Int)` 입력으로 `PetCatalogRepository` 로부터 비동기 이미지를 로드해 표시.
/// 로드 전에는 번들 ImageResource 폴백 placeholder 로 즉시 그려 빈 프레임을 방지한다.
struct PetImageView: View {
    let type: PetType
    let level: Int
    /// nil 이면 부모 레이아웃에 맡긴다. 명시 값 전달 시 `.frame(width:height:)` 적용.
    let size: CGSize?

    @State private var image: UIImage?
    @Dependency(\.petCatalogRepository) private var repository

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // 초기 placeholder — 번들 ImageResource 즉시 표시.
                Image(type.image(for: level))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size?.width, height: size?.height)
        // type 또는 level 이 바뀌면 이전 task cancel + 새 task 시작.
        // 시작 시 placeholder 로 리셋하고 await 후 취소 여부를 확인한 뒤에만 결과를 반영해서,
        // 취소된 이전 task 의 stale 결과가 최신 상태를 덮어쓰지 않게 한다.
        .task(id: PetImageKey(type: type, level: level)) {
            image = nil
            let loaded = await repository.image(for: type, level: level)
            guard !Task.isCancelled else { return }
            image = loaded
        }
    }

    /// `.task(id:)` 입력 키. 두 필드 중 하나라도 변하면 task 재실행 신호.
    private struct PetImageKey: Hashable {
        let type: PetType
        let level: Int
    }
}
