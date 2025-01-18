//
//  SchemaV3_2.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/01/2025.
//

import Foundation
@preconcurrency import SwiftData
import SwiftUI

enum SchemaV3_2: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 2, 0)
    
    static var models: [any PersistentModel.Type] {
        [TaskItem.self, Comment.self]
    }
    
    @Model
    final class TaskItem: Codable {
        public internal(set) var created: Date = Date.now
        public internal(set) var changed: Date = Date.now
        public internal(set) var closed: Date? = nil
        
        var _title: String = emptyTaskTitle
        var _details: String = emptyTaskDetails
        var _state: TaskItemState = TaskItemState.open
        var _url: String = ""
        var uuid: UUID = UUID()
        @Relationship(deleteRule: .cascade, inverse: \Comment.taskItem) var comments: [Comment]? = [Comment]()
        public var dueDate: Date? = nil
        var eventId: String? = nil
        
        // ignore for now
        public var important: Bool = false
        public var urgent: Bool = false
        @Attribute(.externalStorage)
        var _imageData: Data? = nil
        var _priority: Int = 0
        var _tags: [String] = []
        
        init() {
            self.uuid = UUID()
            self.eventId = nil
        }
        
        init(title: String = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open, uuid: UUID = UUID(), eventId : String? = nil) {
            self._title = title
            self._details = details
            self.changed = changedDate
            self.comments = []
            self._state = state
            self._tags = []
            self.uuid = UUID()
            self.eventId = nil
        }
        
        // MARK: Codable

        enum CodingKeys: CodingKey {
            case created, changed, closed, title, details, state, url, comments, important, urgent, imageData, dueDate, priority, tags, uuid, eventId
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(Date.self, forKey: .created)
            self.changed = try container.decode(Date.self, forKey: .changed)
            self.closed = try? container.decode(Date.self, forKey: .closed)
            self._title = try container.decode(String.self, forKey: .title)
            self._details = try container.decode(String.self, forKey: .details)
            self._state = try container.decode(TaskItemState.self, forKey: .state)
            self._url = try container.decode(String.self, forKey: .url)
            self.comments = try container.decode([Comment].self, forKey: .comments)
            self.important = try container.decode(Bool.self, forKey: .important)
            self.urgent = try container.decode(Bool.self, forKey: .urgent)
            self._imageData = try? container.decode(Data.self, forKey: .imageData)
            self.dueDate = try? container.decode(Date.self, forKey: .dueDate)
            self._priority = try container.decode(Int.self, forKey: .priority)
            self._tags = try container.decode([String].self, forKey: .tags)
            if let uuid = try? container.decode(UUID.self, forKey: .uuid) {
                self.uuid = uuid
            } else {
                self.uuid = UUID()
            }
            self.eventId = try? container.decode(String?.self, forKey: .eventId)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
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
            try container.encode(_priority, forKey: .priority)
            try container.encode(created, forKey: .created)
            try container.encode(changed, forKey: .changed)
            try container.encode(_tags, forKey: .tags)
            try container.encode(uuid, forKey: .uuid)
            try container.encode(eventId, forKey: .eventId)
        }
    }
    
    @Model
    final class Comment: Codable {
        var created: Date = Date.now
        var changed: Date = Date.now
        var text: String = ""
        var taskItem: TaskItem? = nil
        
        init(text: String, taskItem: TaskItem) {
            self.text = text
            self.taskItem = taskItem
        }
        
        // MARK: Codable

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
}
