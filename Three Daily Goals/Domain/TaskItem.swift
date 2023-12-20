//
//  Item.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData


enum TaskItemState: Codable {
    case open
    case closed
    case graveyard
}

@Model
final class TaskItem : ObservableObject , Identifiable{
    var created: Date = Date.now
    var changed: Date = Date.now
    var closed: Date? = nil
    var title: String = "I need to ..." {
        didSet {
            changed = Date.now
        }
    }
    var details: String = "(no details yet)" {
        didSet {
            changed = Date.now
        }
    }
    var state: TaskItemState = TaskItemState.open {
        didSet {
            changed = Date.now
            if state == .closed {
                closed = Date.now
            }
            if state == .open {
                closed = nil
            }
            if state == .graveyard {
                closed = nil
            }
        }
    }
    @Relationship(deleteRule: .cascade) var comments : [Comment]? = [Comment]()
    @Relationship(inverse: \DailyTasks.priorities) var priorityOn: [DailyTasks]? = [DailyTasks]()

    init() {
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
    
    var id: Date {
        return created
    }
    
    func addComment(text: String) {
        if let mc = self.modelContext {
            let aComment = Comment(text: text, taskItem: self)
            mc.insert(aComment)
            if comments == nil {
                comments = [Comment]()
            }
            comments?.append(aComment)
        }
    }
    
    func makePriority(position: Int, day: DailyTasks) {
        if var priorities = day.priorities {
            let index = min (priorities.count, position - 1)
            day.priorities?.insert(self, at: index)
            addComment(text: "added as priority \(index + 1) to day \(day.day)")
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
}


