//
//  Item.swift
//  TimesAI
//
//  Created by Om Patel on 2024-06-10.
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
