//
//  NewPetViewModel.swift
//  DDanDDan
//
//  Created by 이지희 on 9/9/25.
//

import Swift
import Combine


final class NewPetViewModel: ObservableObject {
    let dismissPublisher = PassthroughSubject<Void, Never>()
    
    func tapDisMissButton() {
        dismissPublisher.send()
    }
}

