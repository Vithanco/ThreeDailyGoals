//
//  Item.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData
import os
import CoreTransferable

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
    
    // Deep Equality needed during import
    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        let result = lhs.id == rhs.id &&
        lhs.important == rhs.important &&
        lhs.title == rhs.title &&
        lhs.details == rhs.details &&
        lhs.urgent == rhs.urgent &&
        lhs.state == rhs.state &&
        lhs.url == rhs.url &&
        lhs._priority == rhs._priority &&
        lhs._imageData == rhs._imageData &&
        lhs.changed == rhs.changed &&
        lhs.created == rhs.created &&
        lhs.dueDate == rhs.dueDate 
//        (lhs.comments == nil)  == (rhs.comments == nil)
        if !result {
            return false
        }
//        if var lhsComments = lhs.comments, var rhsComments = rhs.comments {
//            if lhsComments.count != rhsComments.count {
//                return false
//            }
//            if lhsComments.isEmpty {
//                return true
//            }
//            lhsComments.sort()
//            rhsComments.sort()
//            for i in 0 ... lhsComments.count-1 {
//                if lhsComments[i] != rhsComments[i] {
//                    return false
//                }
//            }
//        }
        return true
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
    var due: Date? {
        get {
            return self.dueDate
        }
        set {
            self.dueDate = newValue
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
        let states : [TaskItemState] = [.open, .priority, .pendingResponse]
        return states.contains(self.state)
    }
    
    var canBeMovedToOpen : Bool {
        let states : [TaskItemState] = [.pendingResponse, .closed, .dead, .priority]
        return states.contains(self.state)
    }
    
    var canBeTouched : Bool {
        let states : [TaskItemState] = [.pendingResponse, .open, .priority]
        return states.contains(self.state)
    }
    
    var canBeDeleted : Bool {
        let states : [TaskItemState] = [.closed, .dead]
        return states.contains(self.state)
    }
    
    var isDead: Bool {
        return state == .dead
    }
    
    var isPending: Bool {
        return state == .pendingResponse
    }
    
   @discardableResult func addComment(text: String) -> TaskItem{
//        if comments == nil {
//            comments = [Comment]()
//        }
//       
//       let aComment = Comment(text: text, taskItem: self)
//       if let mc = self.modelContext {
//           mc.insert(aComment)
//       }
//       comments?.append(aComment)
//       changed = Date.now
       return self
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
    
    func dueUntil(date: Date) -> Bool {
        if let due {
            return due <= date
        }
        return false
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
            addComment(text: "You did your part. Closure is pending a response.")
        }
    }
}


extension TaskItem : Comparable {
    static func < (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.changed < rhs.changed
    }
}


extension TaskItem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
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
