//
//  Item.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData




@Model
final class TaskItem : ObservableObject, Codable{
    public private (set) var created: Date = Date.now
    public private (set) var changed: Date = Date.now
    public private (set) var closed: Date? = nil
    
    //ignore for now
    public var important: Bool = false
    public var urgent: Bool = false
    
    var _title: String = "I need to ..."
    var _details: String = "(no details yet)"
    var _state: TaskItemState = TaskItemState.open
    
    @Relationship(deleteRule: .cascade) var comments : [Comment]? = [Comment]()
    @Relationship(inverse: \DailyTasks.priorities) var priority: DailyTasks? = nil
    
    init() {
        
    }
    
    init(title: String  = "I need to ...", details: String = "(no details yet)", changedDate: Date = Date.now) {
        self._title = title
        self._details = details
        self.changed = changedDate
    }
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case created, changed, title, details, state, comments, important, urgent
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
    }
}

extension TaskItem: Identifiable {
    var id: Date {
        return created
    }
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
                if newValue == .graveyard {
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
        return state == .graveyard
    }
    
    func addComment(text: String) {
        if let mc = self.modelContext {
            let aComment = Comment(text: text, taskItem: self)
            mc.insert(aComment)
            if comments == nil {
                comments = [Comment]()
            }
            comments?.append(aComment)
            changed = Date.now
        }
    }
    
    func makePriority(position: Int, day: DailyTasks) {
        if let priorities = day.priorities {
            let index = min (priorities.count, position)
            day.priorities?.insert(self, at: index)
            addComment(text: "added as priority to day \(day.day)")
        }
    }
    
    func removePriority() {
        if priority != nil {
            priority = nil
            addComment(text: "removed as priority for \(priority!.day)")
        }
    }
    
    func deleteTask(){
        priority = nil
        modelContext?.delete(self)
        if let comments = comments {
            for c in comments {
                c.deleteComment()
            }
        }
    }
    
    func closeTask() {
        state = .closed
        addComment(text: "closed this task on \(Date.now)")
    }
    
    func reOpenTask() {
        state = .open
        addComment(text: "Reopened this on \(Date.now)")
    }
    
    func touch() {
        state = .open
        addComment(text: "Touched this task on \(Date.now)")
    }
    
    /// only use for test cases
    func setChangedDate(_ date: Date) {
        changed = date
    }
}


extension TaskItem : Comparable {
    static func < (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.changed < rhs.changed
    }
}
