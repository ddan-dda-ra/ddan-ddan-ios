//
//  PetAssetCache.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-12.
//

import CryptoKit
import Foundation

public protocol PetAssetCaching: Sendable {
    func contains(_ url: URL) async -> Bool
    func localURL(for url: URL) async -> URL?
    func data(for url: URL) async -> Data?
    func download(_ url: URL) async -> URL?
    func invalidate(_ url: URL) async
}

/// SVG/JSON을 해석하지 않고 원본 Data 그대로 저장하는 URL 기반 디스크 캐시.
public actor PetAssetCache: PetAssetCaching {
    public static let shared = PetAssetCache(appGroup: "group.com.DdanDdan")

    private let diskRoot: URL
    private let session: URLSession
    private var inflight: [URL: Task<URL?, Never>] = [:]

    public init(appGroup: String, session: URLSession = .shared, diskRoot: URL? = nil) {
        let fm = FileManager.default
        if let diskRoot {
            self.diskRoot = diskRoot
        } else if let container = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            self.diskRoot = container.appendingPathComponent("PetCatalog/Assets", isDirectory: true)
        } else {
            let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.diskRoot = support.appendingPathComponent("DDanDDan/PetCatalog/Assets", isDirectory: true)
        }
        self.session = session
        try? fm.createDirectory(at: self.diskRoot, withIntermediateDirectories: true)
    }

    public func contains(_ url: URL) -> Bool {
        let local = fileURL(for: url)
        guard let data = try? Data(contentsOf: local), Self.isValid(data, for: url) else {
            try? FileManager.default.removeItem(at: local)
            return false
        }
        return true
    }

    public func localURL(for url: URL) -> URL? {
        let local = fileURL(for: url)
        return contains(url) ? local : nil
    }

    public func data(for url: URL) -> Data? {
        guard let local = localURL(for: url) else { return nil }
        return try? Data(contentsOf: local)
    }

    public func download(_ url: URL) async -> URL? {
        if let local = localURL(for: url) { return local }
        if let task = inflight[url] { return await task.value }

        let local = fileURL(for: url)
        let session = self.session
        let task = Task<URL?, Never> {
            guard !Task.isCancelled,
                  let (data, response) = try? await session.data(from: url),
                  let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  Self.isValid(data, for: url) else { return nil }
            do {
                try data.write(to: local, options: .atomic)
                return local
            } catch {
                return nil
            }
        }
        inflight[url] = task
        let result = await task.value
        inflight[url] = nil
        return result
    }

    public func invalidate(_ url: URL) {
        try? FileManager.default.removeItem(at: fileURL(for: url))
    }

    public func prefetch(_ urls: Set<URL>) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [weak self] in _ = await self?.download(url) }
            }
        }
    }

    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }.joined()
        let ext = url.pathExtension.isEmpty ? "asset" : url.pathExtension.lowercased()
        return diskRoot.appendingPathComponent("\(digest).\(ext)")
    }

    private static func isValid(_ data: Data, for url: URL) -> Bool {
        guard !data.isEmpty else { return false }
        switch url.pathExtension.lowercased() {
        case "json": return (try? JSONSerialization.jsonObject(with: data)) != nil
        case "svg":
            guard let value = String(data: data, encoding: .utf8)?.lowercased() else { return false }
            return value.contains("<svg") && value.contains("</svg>")
        default: return false
        }
    }
}
