//
//  SchemaV3_2.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/01/2025.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

//--------------------------------------------------------------------------------
// ⚠️⛔️ new version -- please read ⛔️⚠️
// First, change app to be connected to iCloud development (entitlements File, change com.apple.developer.icloud-container-environment)
// Then develop, then deploy in CloudKit Console to Production, only then switch back entitlements file to production
// ⚠️⛔️ everything else leads to issues - I just lost all tags because I did the migration first in production ⛔️⚠️
// oh! and don't deploy to production before the app is approved
//--------------------------------------------------------------------------------

public enum SchemaV3_6: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 6, 0)

    public static var models: [any PersistentModel.Type] {
        [TaskItem.self, Comment.self, Attachment.self]
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
        @Relationship(deleteRule: .cascade, inverse: \Attachment.taskItem) var attachments: [Attachment]? = []
        public var dueDate: Date? = nil
        var eventId: String? = nil
        var allTagsString: String = ""
        var estimatedMinutes: Int = 0

        //future potential additions:
        //Eisenhower Matrix (Important, Urgent),
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
        var icon: String? = nil
        var state: TaskItemState? = nil

        init(text: String, taskItem: TaskItem, icon: String? = nil, state: TaskItemState? = nil) {
            self.text = text
            self.taskItem = taskItem
            self.icon = icon
            self.state = state
        }

        // MARK: Codable
        enum CodingKeys: CodingKey {
            case created, changed, text, icon, state
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(Date.self, forKey: .created)
            self.changed = try container.decode(Date.self, forKey: .changed)
            self.text = try container.decode(String.self, forKey: .text)
            self.icon = try container.decode(String?.self, forKey: .icon)
            self.state = try container.decode(TaskItemState?.self, forKey: .state)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(created, forKey: .created)
            try container.encode(changed, forKey: .changed)
            try container.encode(text, forKey: .text)
            try container.encode(icon, forKey: .icon)
            try container.encode(state, forKey: .state)
        }
    }

    @Model
    public final class Attachment {
        @Attribute(.externalStorage) var blob: Data?
        var thumbnail: Data?

        var filename: String = ""
        var utiIdentifier: String?
        var byteSize: Int = 0

        var caption: String?
        var sortIndex: Int = 0

        var createdAt: Date = Date.now

        var isPurged: Bool = false
        var purgedAt: Date?
        var nextPurgePrompt: Date?

        var taskItem: TaskItem?

        @Transient var type: UTType? { utiIdentifier.flatMap(UTType.init) }

        public init() {
            createdAt = .now
            filename = ""
            byteSize = 0
            taskItem = .init()
            utiIdentifier = nil
        }
    }

}
