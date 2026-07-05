//
//  PetCatalogNetwork.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-12.
//

import Foundation
import Alamofire

public protocol PetCatalogNetworking: Sendable {
    func fetchCatalog() async -> Result<PetCatalogResponse, NetworkError>
}

public struct PetCatalogNetwork: PetCatalogNetworking, Sendable {
    public init() {}

    public func fetchCatalog() async -> Result<PetCatalogResponse, NetworkError> {
        await NetworkManager().request(url: PathString.Pet.catalog, method: .get)
    }
}
