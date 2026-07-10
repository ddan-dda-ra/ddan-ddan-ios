//
//  PetAssetCache.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-12.
//

import Foundation
import UIKit
import CryptoKit
// TODO: SVGKit SPM 추가 후 decode() 및 import 활성화 — 02_implementer_changes.md [B1] 참조.
// import SVGKit

/// 펫 이미지(SVG/PNG/JPEG) 메모리 + 디스크 캐시.
/// App Group `group.com.DdanDdan` 컨테이너 `pet-assets/` 디렉토리에 sha256 hex 파일명으로 저장한다.
public actor PetAssetCache {
    public static let shared = PetAssetCache(appGroup: "group.com.DdanDdan")

    private let memory = NSCache<NSString, UIImage>()
    private let diskRoot: URL
    private var inflight: [URL: Task<UIImage?, Never>] = [:]

    public init(appGroup: String) {
        let fm = FileManager.default
        let baseURL: URL
        if let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            baseURL = containerURL.appendingPathComponent("pet-assets", isDirectory: true)
        } else {
            // App Group 컨테이너 접근 실패 시 안전 폴백 — crash 금지.
            // 임시 디렉토리는 OS가 정리할 수 있으나, 적어도 컴파일/런타임은 통과.
            // 운영 가시성을 위해 로그를 남긴다 — 타겟 간 캐시 공유가 깨진 신호.
            print("⚠️ PetAssetCache: App Group '\(appGroup)' container missing — fallback to temporaryDirectory")
            baseURL = fm.temporaryDirectory.appendingPathComponent("pet-assets", isDirectory: true)
        }
        self.diskRoot = baseURL
        try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    /// 단일 URL에 대한 이미지 획득. 메모리 → 디스크 → 네트워크 순서.
    public func image(for url: URL) async -> UIImage? {
        // 1) 메모리 hit
        if let cached = memory.object(forKey: url.absoluteString as NSString) {
            return cached
        }

        // 2) 동일 URL inflight 공유 (dedup)
        if let task = inflight[url] {
            return await task.value
        }

        // 3) 새 Task 등록. actor self 캡처 피하기 위해 stored property만 캡처.
        let diskRoot = self.diskRoot
        let memory = self.memory
        let task = Task<UIImage?, Never> {
            let filename = Self.sha256Hex(url.absoluteString)
            let diskURL = diskRoot.appendingPathComponent(filename)

            // 3-a) 디스크 hit
            if let data = try? Data(contentsOf: diskURL), let img = Self.decode(data: data) {
                memory.setObject(img, forKey: url.absoluteString as NSString)
                return img
            }

            // 3-b) 네트워크 fetch → 디스크 write → 메모리 write
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let img = Self.decode(data: data) else {
                return nil
            }
            try? data.write(to: diskURL, options: .atomic)
            memory.setObject(img, forKey: url.absoluteString as NSString)
            return img
        }

        inflight[url] = task
        let result = await task.value
        inflight[url] = nil
        return result
    }

    /// 다수 URL 사전 적재. 결과는 버리고 캐시에만 채운다.
    public func prefetch(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [weak self] in
                    _ = await self?.image(for: url)
                }
            }
        }
    }

    /// 메모리 + 디스크 캐시 전체 비우기. 진행 중 다운로드 Task도 함께 cancel하여
    /// clear 직후 inflight 완료분이 캐시를 재오염시키는 것을 막는다.
    public func clear() async {
        for (_, task) in inflight {
            task.cancel()
        }
        inflight.removeAll()
        memory.removeAllObjects()
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(at: diskRoot, includingPropertiesForKeys: nil) {
            for item in items {
                try? fm.removeItem(at: item)
            }
        }
    }

    // MARK: - Helpers

    /// SVG 우선 → UIImage 폴백. 현재 SVGKit 미등록으로 UIImage 폴백만 동작.
    private static func decode(data: Data) -> UIImage? {
        // TODO: SVGKit SPM 추가 후 아래 블록 활성화.
        // if let svg = SVGKImage(data: data), let img = svg.uiImage {
        //     return img
        // }
        return UIImage(data: data)
    }

    private static func sha256Hex(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
