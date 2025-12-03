//
//  SchemaV3_2.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/01/2025.
//

import Foundation
import SwiftData
import SwiftUI

//--------------------------------------------------------------------------------
// ⚠️⛔️ new version -- please read ⛔️⚠️
// First, change app to be connected to iCloud development (entitlements File, change com.apple.developer.icloud-container-environment)
// Then develop, then deploy in CloudKit Console to Production, only then switch back entitlements file to production
// ⚠️⛔️ everything else leads to issues - I just lost all tags because I did the migration first in production ⛔️⚠️
// oh! and don't deploy to production before the app is approved
//--------------------------------------------------------------------------------
public enum SchemaV3_4: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 4, 0)

    public static var models: [any PersistentModel.Type] {
        [TaskItem.self, Comment.self]
    }

    @Model
    public final class TaskItem: Codable {
        public internal(set) var created: Date = Date.now
        public internal(set) var changed: Date = Date.now
        public internal(set) var closed: Date? = nil

        var _title: String = emptyTaskTitle
        var _details: String = emptyTaskDetails
        var _state: TaskItemState = TaskItemState.open
        var _url: String = ""
        var uuid: UUID = UUID()
        @Relationship(deleteRule: .cascade, inverse: \Comment.taskItem) var comments: [Comment]? = [
            Comment
        ]()
        public var dueDate: Date? = nil
        var eventId: String? = nil
        var allTagsString: String = ""
        var estimatedMinutes: Int = 0

        //future potential additions:
        //EnergyEffort Matrix (Important, Urgent),
        //Priority (1-10)
        //ImageData

        init() {
            self.uuid = UUID()
            self.eventId = nil
        }

        init(
            title: String = emptyTaskTitle,
            details: String = emptyTaskDetails,
            changedDate: Date = Date.now,
            state: TaskItemState = .open,
            uuid: UUID = UUID(),
            eventId: String? = nil,
            estimatedMinutes: Int = 0
        ) {
            self._title = title
            self._details = details
            self.changed = changedDate
            self.comments = []
            self._state = state
            self._url = ""
            self.allTagsString = ""
            self.uuid = uuid
            self.eventId = nil
            self.estimatedMinutes = estimatedMinutes
        }

        // MARK: Codable

        enum CodingKeys: CodingKey {
            case created, changed, closed, title, details, state, url, comments, dueDate, tags, uuid,
                eventId, estimatedMinutes
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(Date.self, forKey: .created)
            self.changed = try container.decode(Date.self, forKey: .changed)
            self.closed = try? container.decode(Date.self, forKey: .closed)
            self._title = try container.decode(String.self, forKey: .title)
            self._details = try container.decode(String.self, forKey: .details)
            self._state = try container.decode(TaskItemState.self, forKey: .state)
            self._url = try container.decode(String.self, forKey: .url)
            self.comments = try container.decode([Comment].self, forKey: .comments)
            self.dueDate = try? container.decode(Date.self, forKey: .dueDate)
            self.allTagsString = try container.decode(String.self, forKey: .tags)
            if let uuid = try? container.decode(UUID.self, forKey: .uuid) {
                self.uuid = uuid
            } else {
                self.uuid = UUID()
            }
            self.eventId = try? container.decode(String?.self, forKey: .eventId)
            self.estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(closed, forKey: .closed)
            try container.encode(_title, forKey: .title)
            try container.encode(_details, forKey: .details)
            try container.encode(_state, forKey: .state)
            try container.encode(_url, forKey: .url)
            try container.encode(comments, forKey: .comments)
            try container.encode(dueDate, forKey: .dueDate)
            try container.encode(created, forKey: .created)
            try container.encode(changed, forKey: .changed)
            try container.encode(allTagsString, forKey: .tags)
            try container.encode(uuid, forKey: .uuid)
            try container.encode(eventId, forKey: .eventId)
            try container.encode(estimatedMinutes, forKey: .estimatedMinutes)
        }
    }

    @Model
    public final class Comment: Codable {
        var created: Date = Date.now
        var changed: Date = Date.now
        var text: String = ""
        var taskItem: TaskItem? = nil

        init(text: String, taskItem: TaskItem) {
            self.text = text
            self.taskItem = taskItem
        }

        init(old: SchemaV3_3.Comment) {
            self.text = old.text
            self.created = old.created
            self.changed = old.created
        }

        // MARK: Codable

        enum CodingKeys: CodingKey {
            case created, changed, text
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(Date.self, forKey: .created)
            self.changed = try container.decode(Date.self, forKey: .changed)
            self.text = try container.decode(String.self, forKey: .text)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(created, forKey: .created)
            try container.encode(changed, forKey: .changed)
            try container.encode(text, forKey: .text)
        }
    }
}
