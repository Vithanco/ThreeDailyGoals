//
//  SchemaV1.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation
@preconcurrency import SwiftData
import SwiftUI



enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [TaskItem.self, Comment.self, Preferences.self]
    }
    
    @Model
    final class TaskItem : ObservableObject, Codable {
        
        public internal(set) var created: Date = Date.now
        public internal(set) var changed: Date = Date.now
        public internal(set) var closed: Date? = nil
        
        //ignore for now
        public var important: Bool = false
        public var urgent: Bool = false
        public var dueDate: Date? = nil
        
        var _title: String = emptyTaskTitle
        var _details: String = emptyTaskDetails
        var _state: TaskItemState = TaskItemState.open
        var _url: String = ""
        
        @Relationship(deleteRule: .cascade) var comments : [Comment]? = [Comment]()
        
        init() {
            
        }
        
        init(title: String  = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now) {
            self._title = title
            self._details = details
            self.changed = changedDate
            self.comments = []
        }
        
        //MARK: Codable
        enum CodingKeys: CodingKey {
            case created, changed, title, details, state, comments, important, urgent, url
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(Date.self, forKey: .created)
            self.changed = try container.decode(Date.self, forKey: .changed)
            self._title = try container.decode(String.self, forKey: .title)
            self._details = try container.decode(String.self, forKey: .details)
            self._state = try container.decode(TaskItemState.self, forKey: .state)
            self.comments = try container.decode(Array<Comment>.self, forKey: .comments)
            self.important = try container.decode(Bool.self, forKey: .important)
            self.urgent = try container.decode(Bool.self, forKey: .urgent)
            self._url = try container.decode(String.self, forKey: .url)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(created, forKey: .created)
            try container.encode(changed, forKey: .changed)
            try container.encode(_title, forKey: .title)
            try container.encode(_details, forKey: .details)
            try container.encode(_state, forKey: .state)
            try container.encode(_title, forKey: .title)
            try container.encode(comments, forKey: .comments)
            try container.encode(important, forKey: .important)
            try container.encode(urgent, forKey: .urgent)
            try container.encode(_url, forKey: .url)
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
        @Transient
        var reviewTimeHour: Int = 18
        @Transient
        var reviewTimeMinutes: Int = 0
        
        @Transient
        var reviewTime: Date {
            set {
                reviewTimeHour = Calendar.current.component(.hour, from: newValue)
                reviewTimeMinutes = Calendar.current.component(.minute, from: newValue)
            }
            get {
                var date = Calendar.current.date(bySettingHour: reviewTimeHour, minute: reviewTimeMinutes, second: 0, of: Date())!
                if date < Date.now {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                }
                return date
            }
        }
        
        @Transient
        var accentColor: Color {
            get {
                if mainColorString == "" {
                    return Color.accentColor
                }
                return Color(hex: mainColorString)
            }
            set {
                if let string = newValue.toHex {
                    mainColorString = string
                } else {
                    mainColorString = ""
                }
                
            }
        }
        
        
        init(){
            
        }
    }
    
    
}
