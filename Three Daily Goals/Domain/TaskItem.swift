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

typealias TaskItem = SchemaLatest.TaskItem

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
    
    var isPriority: Bool {
        return state == .priority
    }
    
    var isOpenOrPriority: Bool {
        return state == .open || state == .priority
    }
    
    var isClosed: Bool {
        return state == .closed
    }
    
    var canBeClosed : Bool {
        return state == .open || state == .priority || state == .pendingResponse
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
            addComment(text: "You 'touched' this task.")
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
