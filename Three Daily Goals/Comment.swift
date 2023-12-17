//
//  Comment.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftData
import Foundation

@Model
final class Comment: ObservableObject, Identifiable {
    var created: Date
    var changed: Date
    var text: String
    
    init(text: String) {
        let now = Date.now
        self.created = now
        self.changed = now
        self.text = text
    }
    
    var id: Date {
        return created
    }
}
