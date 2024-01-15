//
//  Item.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: TaskItem.self)
)

@Model
final class TaskItem : ObservableObject, Codable {
    
    public private (set) var created: Date = Date.now
    public private (set) var changed: Date = Date.now
    public private (set) var closed: Date? = nil
    
    //ignore for now
    public var important: Bool = false
    public var urgent: Bool = false
    
    var _title: String = "I need to ..."
    var _details: String = "(no details yet)"
    var _state: TaskItemState = TaskItemState.open
    var _url: String = ""
    
    @Relationship(deleteRule: .cascade) var comments : [Comment]? = [Comment]()
//    @Relationship(inverse: \DailyTasks.priorities) var priority: DailyTasks? = nil
    
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

extension TaskItem: Identifiable {
    var id: String {
        let result = created.timeIntervalSince1970.description
//        logger.debug("ID for Task '\(self.title)' is \(result), from \(self.created.timeIntervalSince1970)")
        return result
    }
}

extension TaskItem:Equatable {
    
}

extension TaskItem {
    @Transient
    var title: String {
        get {
            return _title
        }
        set {
            _title = newValue
            changed = Date.now
        }
    }
    
    @Transient
    var details: String {
        get {
            return _details
        }
        set {
            _details = newValue
            changed = Date.now
        }
    }
    
    @Transient
    var url: String {
        get {
            return _url
        }
        set {
            _url = newValue
            changed = Date.now
        }
    }
    
    @Transient
    var state: TaskItemState {
        get {
            return _state
        }
        set {
            if (newValue != state) {
                changed = Date.now
//                addComment(text: "Changed state to: \(newValue)")
                _state = newValue
                if newValue == .closed {
                    closed = Date.now
                }
                if newValue == .open {
                    closed = nil
                }
                if newValue == .dead {
                    closed = nil
                }
            }
        }
    }
    
    var isOpen: Bool {
        return state == .open
    }
    
    var isClosed: Bool {
        return state == .closed
    }
    
    var isGraveyarded: Bool {
        return state == .dead
    }
    
    var isPending: Bool {
        return state == .pendingResponse
    }
    
    func addComment(text: String) {
        if comments == nil {
            comments = [Comment]()
        }
        if let mc = self.modelContext, var comments = comments {
            let aComment = Comment(text: text, taskItem: self)
            mc.insert(aComment)
            comments.append(aComment)
            changed = Date.now
        }
    }
    
//    func makePriority(position: Int, day: DailyTasks) {
//        reOpenTask()
//        if let priorities = day.priorities {
//            let index = min (priorities.count, position)
//            day.priorities?.insert(self, at: index)
//            addComment(text: "added as priority to day \(day.day)")
//        }
//    }
//    
//    func removePriority() {
//        if priority != nil {
//            addComment(text: "removed as priority for \(priority!.day)")
//            priority = nil
//        }
//    }
    
//    func deleteTask(){
//        modelContext?.delete(self)
//        modelContext?.processPendingChanges()
//    }
    
    func closeTask() {
        if state != .closed {
            state = .closed
            addComment(text: "closed this task on \(Date.now)")
        }
    }
    
    func reOpenTask() {
        if state != .open {
            state = .open
            addComment(text: "Reopened this Task.")
        }
    }
    func graveyard() {
        if state != .dead {
            state = .dead
            addComment(text: "Moved task to the Graveyard of not needed tasks.")
        }
    }
    
    func makePriority() {
        if state != .priority {
            state = .priority
            addComment(text: "Turned into a priority.")
        }
    }
    
    func touch() {
        if state == .open {
            addComment(text: "Touched this task.")
        } else {
            reOpenTask()
        }
    }
    
    /// only use for test cases
    func setChangedDate(_ date: Date) {
        changed = date
    }
    
    func pending() {
        if state != .pendingResponse {
            state = .pendingResponse
            addComment(text: "Done! But pending Response.")
        }
    }
}


extension TaskItem : Comparable {
    static func < (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.changed < rhs.changed
    }
}


//import UniformTypeIdentifiers
//import SwiftUI
//
//    extension UTType {
//        static var taskItem: UTType = UTType(exportedAs: "com.vithanco.three-daily-goals.taskitem")
//    }
//
//extension TaskItem: Transferable {
//    static var transferRepresentation: some TransferRepresentation {
//                CodableRepresentation(contentType: .taskItem)
//            }
//}
