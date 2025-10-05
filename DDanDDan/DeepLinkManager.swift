//
//  DeepLinkManager.swift
//  DDanDDan
//
//  Created by 이지희 on 10/5/25.
//

import UIKit
import Combine

import ChottuLinkSDK


enum DeepLinkType: Equatable {
    case friendInvite(code: String)
}

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingDeepLink: DeepLinkType?
    
    private init() {}
    
    func handleFriendInvite(code: String) {
        NotificationCenter.default.post(
            name: .friendInviteDeepLink,
            object: code
            )
    }
    
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
}

struct InviteLinkBuilder {
    let baseInviteURL: URL
    
    /// 서버에서 받은 친구 코드로 초대 링크 생성
    func makeInviteURL(friendCode: String) async -> URL? {
        guard !friendCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        let builder = CLDynamicLinkBuilder(
            destinationURL: baseInviteURL.absoluteString,
            domain: "ddanddan.chottu.link"
        )
            .setIOSBehaviour(.app)
            .setAndroidBehaviour(.browser)
            .setLinkName("friend-invite")
            .setSelectedPath(friendCode)
            .build()
        
        do {
            let shortURL = try await ChottuLink.createDynamicLink(for: builder)
            print("✅ Created link: \(shortURL)")
            return URL(string: shortURL ?? "")
            // Share the link with your users
        } catch {
            print("❌ Failed to create link: \(error)")
            // Handle the error appropriately
            return nil
        }
    }
}

enum Clipboard {
    static func copy(_ string: String) {
        UIPasteboard.general.string = string
    }
    static func copy(_ url: URL) {
        UIPasteboard.general.url = url
    }
}
