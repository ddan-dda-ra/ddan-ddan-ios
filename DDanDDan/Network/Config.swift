//
//  Config.swift
//  DDanDDan
//
//  Created by 이지희 on 11/21/24.
//

import Foundation

enum Config {
    enum Keys {
        enum Plist {
            static let baseURL = "BASE_URL"
            static let kakaoKey = "KAKAO_KEY"
            static let chottulinkKey = "CHOTTULINK_KEY"
        }
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist cannot found.")
        }
        return dict
    }()
    
    static let baseURL: String = {
        guard let key = Config.infoDictionary[Keys.Plist.baseURL] as? String else {
            fatalError("Base URL is not set in plist for this configuration.")
        }
        return key
    }()
    
    static let kakaoKey: String = {
        guard let key = Config.infoDictionary[Keys.Plist.kakaoKey] as? String else {
            fatalError("kakao key is not set in plist for this configuration.")
        }
        return key
    }()
    
    static let chottulinkKey: String = {
        guard let key = Config.infoDictionary[Keys.Plist.chottulinkKey] as? String else {
            fatalError("Chottu-link key is not set in plist for this configuration.")
        }
        return key
    }()
}
