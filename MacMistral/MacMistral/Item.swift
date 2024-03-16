//
//  Item.swift
//  MacMistral
//
//  Created by Petros Dhespollari on 16/3/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
