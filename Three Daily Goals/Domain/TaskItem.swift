//
//  Item.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import CoreTransferable
import CryptoKit
import Foundation
import SwiftData
import UniformTypeIdentifiers
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: TaskItem.self)
)

public typealias TaskItem = SchemaLatest.TaskItem

extension TaskItem: Identifiable {
    public var id: String {
        return uuid.uuidString
    }
}

// Deep Equality needed during import
public func deepEqual(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
    let result =
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.details == rhs.details
        && lhs.state == rhs.state && lhs.url == rhs.url
        && lhs.changed == rhs.changed && lhs.created == rhs.created && lhs.dueDate == rhs.dueDate
        && lhs.eventId == rhs.eventId
        && lhs.due == rhs.due && lhs.closed == rhs.closed && lhs.allTagsString == rhs.allTagsString
        && lhs.uuid == rhs.uuid
        && lhs.estimatedMinutes == rhs.estimatedMinutes
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

extension TaskItem: Equatable {

    public static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}

protocol Taggable {
    var tags: [String] { get }
    func addTag(_ newTag: String)
    func removeTag(_ oldTag: String)
}

extension TaskItem: Taggable {
    
    func updateFrom(_ other: TaskItem) {
        if other.uuid != self.uuid {
            logger.error("UUID mismatch during import: \(other.uuid) != \(self.uuid) for  \(self.title) ")
        }
        self._title = other._title
        self._details = other._details
        self.dueDate = other.dueDate
        self._url = other._url
        self.changed = other.changed
        self.allTagsString = other.allTagsString
        self.comments = other.comments
        self.state = other.state
        self.eventId = other.eventId
        self.created = other.created
        self.closed = other.closed
        self.estimatedMinutes = other.estimatedMinutes
    }
}

extension TaskItem {
    @Transient
    var title: String {
        get {
            return _title
        }
        set {
            if newValue != _title {
                _title = newValue
                changed = Date.now
            }
        }
    }

    @Transient
    var details: String {
        get {
            return _details
        }
        set {
            if newValue != _details {
                _details = newValue
                changed = Date.now
            }
        }
    }

    @Transient
    var due: Date? {
        get {
            return self.dueDate
        }
        set {
            if newValue != self.dueDate {
                self.dueDate = newValue
                changed = Date.now
            }
        }
    }

    @Transient
    var url: String {
        get {
            return _url
        }
        set {
            if newValue != _url {
                _url = newValue
                changed = Date.now
            }
        }
    }

    @Transient
    var state: TaskItemState {
        get {
            return _state
        }
        set {
            if newValue != state {
                changed = Date.now
                addComment(text: "Changed state to: \(newValue)", icon: imgStateChange)
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

    @Transient
    var tags: [String] {
        get {
            return allTagsString.components(separatedBy: ",")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        set {
            let oldTags: [String] = self.tags
            
            // Filter out empty and whitespace-only strings, and trim whitespace from valid tags
            let filteredTags = newValue
                .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            if filteredTags != oldTags {
                changed = Date.now
                
                // Add comments for new tags
                filteredTags.filter { !oldTags.contains($0) }.forEach { 
                    addComment(text: "Added tag: \($0)", icon: imgTag) 
                }
                
                // Add comments for removed tags
                oldTags.filter { !filteredTags.contains($0) }.forEach { 
                    addComment(text: "Removed tag: \($0)", icon: imgTag) 
                }
                
                allTagsString = filteredTags.joined(separator: ",")
            }
        }
    }

    func addTag(_ newTag: String) {
        var tags = self.tags
        if !tags.contains(newTag) {
            tags.append(newTag)
            changed = Date.now
            self.tags = tags
        }
        assert(tags.contains(newTag))
    }

    func removeTag(_ oldTag: String) {
        var tags = self.tags
        if tags.contains(oldTag) {
            tags.removeObject(oldTag)
            changed = Date.now
            self.tags = tags
        }
        assert(!tags.contains(oldTag))
    }

    var isEmpty: Bool {
        return (title.isEmpty || title == emptyTaskTitle) && (details.isEmpty || details == emptyTaskDetails)
            && url.isEmpty
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

    var isActive: Bool {
        return [.open, .priority, .pendingResponse].contains(self.state)
    }

    var canBeMadePriority: Bool {
        return [.open, .pendingResponse].contains(self.state)
    }

    var canBeClosed: Bool {
        return [.open, .priority, .pendingResponse, .dead].contains(self.state)
    }

    var canBeMovedToOpen: Bool {
        return self.state != .open
    }

    var canBeMovedToPendingResponse: Bool {
        return self.state != .pendingResponse
    }

    var canBeTouched: Bool {
        return [.pendingResponse, .open, .priority, .dead].contains(self.state)
    }

    var canBeDeleted: Bool {
        return [.closed, .dead].contains(self.state)
    }

    var isDead: Bool {
        return state == .dead
    }

    var isPending: Bool {
        return state == .pendingResponse
    }

    @discardableResult func addComment(text: String, icon: String? = nil, state: TaskItemState? = nil) -> TaskItem {
        if comments == nil {
            comments = [Comment]()
        }

        let aComment = Comment(text: text, taskItem: self, icon: icon, state: state)
        if let mc = self.modelContext {
            mc.insert(aComment)
        }
        comments?.append(aComment)
        changed = Date.now
        return self
    }

    func closeTask() {
        if state != .closed {
            state = .closed
            addComment(text: "closed this task on \(Date.now)", icon: imgClosed, state: .closed)
        }
    }

    func reOpenTask() {
        if state != .open {
            state = .open
            addComment(text: "Reopened this Task.", icon: imgOpen, state: .open)
        }
    }
    func graveyard() {
        if state != .dead {
            state = .dead
            addComment(text: "Moved task to the Graveyard of not needed tasks.", icon: imgGraveyard, state: .dead)
        }
    }

    func makePriority() {
        if state != .priority {
            state = .priority
            addComment(text: "Turned into a priority.", icon: imgPriority, state: .priority)
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
            addComment(text: "You 'touched' this task.", icon: imgTouch)
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
            addComment(text: "You did your part. Closure is pending a response.", icon: imgPendingResponse, state: .pendingResponse)
        }
    }

    func purgeableStoredBytes(at date: Date = Date()) -> Int {
        return attachments?.reduce(0) { $0 + ($1.isDueForPurge(at: date) ? $1.storedBytes : 0) } ?? 0
    }
    var totalStoredBytes: Int { attachments?.reduce(0) { $0 + $1.storedBytes } ?? 0 }  // current storage
    var totalOriginalBytes: Int { attachments?.reduce(0) { $0 + $1.byteSize } ?? 0 }  // original sizes

    var isUnchanged: Bool {
        return isTitleEmpty && isDetailsEmpty &&  url.isEmpty && !hasAttachments
    }
    
    var isTitleEmpty: Bool {
        return title.isEmpty || title == emptyTaskTitle
    }
    
    var isDetailsEmpty: Bool {
        return details.isEmpty || details == emptyTaskDetails
    }
    
    var hasAttachments: Bool {
        if let attachments = attachments {
            return !attachments.isEmpty
        }
        return false
    }
    
}
extension TaskItem: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        return title
    }
    public var debugDescription: String {
        return title
    }
}

extension TaskItem: Comparable {
    public static func < (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.changed < rhs.changed
    }
}

extension TaskItem: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
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
extension Sequence where Element: TaskItem {
    var tags: Set<String> {
        var result = Set<String>()
        for t in self {
            result.formUnion(t.tags)
        }
        for t in result where t.isEmpty {
            result.remove(t)
        }
        return result
    }

    var activeTags: Set<String> {
        var result = Set<String>()
        for t in self where !t.tags.isEmpty && t.isActive {
            result.formUnion(t.tags)
        }
        result.formUnion(["work", "private"])
        return result
    }

}
