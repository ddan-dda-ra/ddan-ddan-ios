//
//  File.swift
//  DDanDDan
//
//  Created by hwikang on 10/28/24.
//

import Foundation

public struct Pet: Decodable, Equatable {
    let id: String
    let type: PetType
    let level: Int
    let expPercent: Double
}
