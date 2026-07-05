//
//  RepositoryDependency.swift
//  DDanDDan
//
//  Created by keone on 9/23/25.
//

import Dependencies

extension DependencyValues {
    var friendCardRepository: FriendCardRepository {
        get { self[FriendCardRepository.self] }
        set { self[FriendCardRepository.self] = newValue }
    }

    var petCatalogRepository: PetCatalogRepository {
        get { self[PetCatalogRepository.self] }
        set { self[PetCatalogRepository.self] = newValue }
    }
}
