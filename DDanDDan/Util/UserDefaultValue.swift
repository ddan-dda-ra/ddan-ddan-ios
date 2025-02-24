//
//  UserDefault.swift
//  DDanDDan
//
//  Created by hwikang on 7/21/24.
//

import Foundation

public struct UserDefaultValue {
    //Auth
    @UserDefault(key: "acessToken", defaultValue: nil)
    static public var acessToken: String?
    @UserDefault(key: "refreshToken", defaultValue: nil)
    static public var refreshToken: String?
    @UserDefault(key: "deviceToken", defaultValue: nil)
    static public var deviceToken: String?

    @UserDefault(key: "isOnboardingComplete", defaultValue: false)
    static public var isOnboardingComplete: Bool
    @UserDefault(key: "requestAuthDone", defaultValue: false)
    static public var requestAuthDone: Bool
    @UserDefault(key: "needToShowOnboarding", defaultValue: true)
    static public var needToShowOnboarding: Bool
    
    // Main
    @UserDefault(key: "purposeKcal", defaultValue: 0)
    static public var purposeKcal: Int
    @UserDefault(key: "level", defaultValue: 1)
    static public var level: Int
    @UserDefault(key: "userId", defaultValue: "")
    static public var userId: String
    @UserDefault(key: "nickName", defaultValue: "")
    static public var nickName: String

    @UserDefault(key: "petId", defaultValue: "")
    static public var petId: String
    
    @UserDefault(key: "petType", defaultValue: "DOG")
    static public var petType: String
    
    // 보상을 위한 값
    @UserDefault(key: "date", defaultValue: Date())
    static public var date: Date
    @UserDefault(key: "currentKcal", defaultValue: 0)
    static public var currentKcal: Double
    
}

@propertyWrapper
public struct UserDefault<T> {
    public let key: String
    let defaultValue: T
    
    public var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let value = newValue as? OptionalProtocol, value.isNil {
                UserDefaults.standard.removeObject(forKey: key)
            } else {
                UserDefaults.standard.set(newValue, forKey: key)
            }
        }
    }
}

protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    var isNil: Bool { self == nil }
}
