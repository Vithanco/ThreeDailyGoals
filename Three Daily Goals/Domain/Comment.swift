//
//  Comment.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftData
import Foundation

@Model
final class Comment: ObservableObject, Identifiable, Codable{
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
    
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case created, changed, text
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.created = try container.decode(Date.self, forKey: .created)
        self.changed = try container.decode(Date.self, forKey: .changed)
        self.text = try container.decode(String.self, forKey: .text)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(created, forKey: .created)
        try container.encode(changed, forKey: .changed)
        try container.encode(text, forKey: .text)
    }
}


extension Comment : Comparable {
    static func < (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.changed < rhs.changed
    }
}
