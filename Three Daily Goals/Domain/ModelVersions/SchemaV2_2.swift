//
//  SchemaV1.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation
import SwiftData
import SwiftUI



enum SchemaV2_2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 2, 0)
    
    static var models: [any PersistentModel.Type] {
        [TaskItem.self, Comment.self, Preferences.self]
    }
    
    @Model
    final class TaskItem : ObservableObject, Codable {
        
        public internal (set) var created: Date = Date.now
        public internal (set) var changed: Date = Date.now
        public internal (set) var closed: Date? = nil
        
        var _title: String = "I need to ..."
        var _details: String = "(no details yet)"
        var _state: TaskItemState = TaskItemState.open
        var _url: String = ""
        @Relationship(deleteRule: .cascade) var comments : [Comment]? = [Comment]()
        
        //ignore for now
        public var important: Bool = false
        public var urgent: Bool = false
        @Attribute(.externalStorage)
        var _imageData: Data? = nil
        public var dueDate: Date? = nil
        
        init() {
            
        }
        
        init(title: String  = "I need to ...", details: String = "(no details yet)", changedDate: Date = Date.now) {
            self._title = title
            self._details = details
            self.changed = changedDate
            self.comments = []
        }
        
        //MARK: Codable
        enum CodingKeys: CodingKey {
            case created, changed, closed, title, details, state, url, comments, important, urgent,  imageData, dueDate
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(Date.self, forKey: .created)
            self.changed = try container.decode(Date.self, forKey: .changed)
            self.closed = try container.decode(Date.self, forKey: .closed)
            self._title = try container.decode(String.self, forKey: .title)
            self._details = try container.decode(String.self, forKey: .details)
            self._state = try container.decode(TaskItemState.self, forKey: .state)
            self._url = try container.decode(String.self, forKey: .url)
            self.comments = try container.decode(Array<Comment>.self, forKey: .comments)
            self.important = try container.decode(Bool.self, forKey: .important)
            self.urgent = try container.decode(Bool.self, forKey: .urgent)
            self._imageData = try container.decode(Data.self, forKey: .imageData)
            self.dueDate = try container.decode(Date.self, forKey: .dueDate)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(created, forKey: .created)
            try container.encode(changed, forKey: .changed)
            try container.encode(closed, forKey: .closed)
            try container.encode(_title, forKey: .title)
            try container.encode(_details, forKey: .details)
            try container.encode(_state, forKey: .state)
            try container.encode(_url, forKey: .url)
            try container.encode(comments, forKey: .comments)
            try container.encode(important, forKey: .important)
            try container.encode(urgent, forKey: .urgent)
            try container.encode(_imageData, forKey: .imageData)
            try container.encode(dueDate, forKey: .dueDate)
        }
        
    }
    
    
    @Model
    final class Comment: ObservableObject, Codable{
        var created: Date  = Date.now
        var changed: Date  = Date.now
        var text: String = ""
        @Relationship(inverse:  \TaskItem.comments) var taskItem: TaskItem? = nil
        
        init(text: String, taskItem: TaskItem) {
            self.text = text
            self.taskItem = taskItem
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
    
    
    @Model
    final class Preferences: ObservableObject {
        
        var mainColorString : String = ""
        var reviewTimeHour: Int = 18
        var reviewTimeMinutes: Int = 0
        var lastReview: Date = getDate(daysPrior: 365)
        
        init(){
            
        }
    }
    
    
}
