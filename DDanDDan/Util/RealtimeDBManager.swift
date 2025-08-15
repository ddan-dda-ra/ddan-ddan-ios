//
//  RealtimeDBManager.swift
//  DDanDDan
//
//  Created by Assistant on 2024.
//

import Foundation
import FirebaseDatabase

class RealtimeDBManager {
    static let shared = RealtimeDBManager()
    
    private let database = Database.database()
    
    private init() {}
    
    func getValue<T: Codable>(path: String, type: T.Type) async throws -> T? {
        let ref = database.reference().child(path)
        let snapshot = try await ref.getData()
        
        guard let value = snapshot.value, !(value is NSNull) else {
            return nil
        }
        
        let data = try JSONSerialization.data(withJSONObject: value)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func getStringValue(path: String) async throws -> String? {
        let ref = database.reference().child(path)
        let snapshot = try await ref.getData()
        
        return snapshot.value as? String
    }
    
    func getIntValue(path: String) async throws -> Int? {
        let ref = database.reference().child(path)
        let snapshot = try await ref.getData()
        
        return snapshot.value as? Int
    }
    
    func getBoolValue(path: String) async throws -> Bool? {
        let ref = database.reference().child(path)
        let snapshot = try await ref.getData()
        
        return snapshot.value as? Bool
    }
    
    func getDictionaryValue(path: String) async throws -> [String: Any]? {
        let ref = database.reference().child(path)
        let snapshot = try await ref.getData()
        
        return snapshot.value as? [String: Any]
    }
}