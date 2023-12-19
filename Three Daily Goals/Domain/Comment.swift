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
    var created: Date  = Date.now
    var changed: Date  = Date.now
    var text: String = ""
    @Relationship(inverse:  \TaskItem.comments) var taskItem: TaskItem? = nil
    
    init(text: String, taskItem: TaskItem) {
        self.text = text
        self.taskItem = taskItem
    }
    
    var id: Date {
        return created
    }
}
