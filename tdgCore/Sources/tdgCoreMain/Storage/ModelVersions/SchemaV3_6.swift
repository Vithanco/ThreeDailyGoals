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

        public var _title: String = emptyTaskTitle
        public var _details: String = emptyTaskDetails
        public var _state: TaskItemState = TaskItemState.open
        public var _url: String = ""
        public var uuid: UUID = UUID()
        @Relationship(deleteRule: .cascade, inverse: \Comment.taskItem) public var comments: [Comment]? = []
        @Relationship(deleteRule: .cascade, inverse: \Attachment.taskItem) public var attachments: [Attachment]? = []
        public var dueDate: Date? = nil
        public var eventId: String? = nil
        public var allTagsString: String = ""
        public var estimatedMinutes: Int = 0

        //future potential additions:
        //EnergyEffort Matrix (Important, Urgent),
        //Priority (1-10)
        //ImageData

        public init() {
            self.uuid = UUID()
            self.eventId = nil
            self.comments = []
        }

        public init(
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
            self.comments = try container.decodeIfPresent([Comment].self, forKey: .comments) ?? []
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
        public var created: Date = Date.now
        public var changed: Date = Date.now
        public var text: String = ""
        public var taskItem: TaskItem? = nil
        public var icon: String? = nil
        public var state: TaskItemState? = nil

        public init(text: String, taskItem: TaskItem, icon: String? = nil, state: TaskItemState? = nil) {
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
        @Attribute(.externalStorage) public var blob: Data?
        public var thumbnail: Data?
        public var filename: String = ""
        public var utiIdentifier: String?
        public var byteSize: Int = 0
        public var caption: String?
        public var sortIndex: Int = 0
        public var createdAt: Date = Date.now
        public var isPurged: Bool = false
        public var purgedAt: Date?
        public var nextPurgePrompt: Date?
        public var taskItem: TaskItem?

        @Transient public var type: UTType? { utiIdentifier.flatMap(UTType.init) }

        public init() {
            createdAt = .now
            filename = ""
            byteSize = 0
            taskItem = .init()
            utiIdentifier = nil
        }
    }

}
