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

public protocol Taggable {
    var tags: [String] { get }
    func addTag(_ newTag: String)
    func removeTag(_ oldTag: String)
}

extension TaskItem: Taggable {

    public func updateFrom(_ other: TaskItem) {
        if other.uuid != self.uuid {
            logger.error("UUID mismatch during import: \(other.uuid) != \(self.uuid) for  \(self.title) ")
        }
        setTitle(other._title)
        setDetails(other._details)
        setDueDate(other.dueDate)
        setUrl(other._url)
        self.changed = other.changed
        setTags(other.tags)
        self.comments = other.comments
        setState(other._state)
        self.eventId = other.eventId
        self.created = other.created
        self.closed = other.closed
        setEstimatedMinutes(other.estimatedMinutes)
    }
}

extension TaskItem {
    @Transient
    public var title: String {
        get { _title }
        set { _title = newValue }
    }

    @Transient
    public var details: String {
        get { _details }
        set { _details = newValue }
    }

    @Transient
    public var due: Date? {
        get { dueDate }
        set { dueDate = newValue }
    }

    @Transient
    public var url: String {
        get { _url }
        set { _url = newValue }
    }

    @Transient
    public var state: TaskItemState {
        get { _state }
        set { _state = newValue }
    }

    @Transient
    public var tags: [String] {
        get {
            return allTagsString.components(separatedBy: ",")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        set {
            updateTags(newValue, createComments: true)
        }
    }

    /// Set tags with optional comment creation
    public func setTags(_ newTags: [String], createComments: Bool = true) {
        updateTags(newTags, createComments: createComments)
    }

    /// Internal method to update tags with control over comment creation
    private func updateTags(_ newTags: [String], createComments: Bool) {
        // Get old tags for comparison
        let oldTags = self.tags

        // Filter out empty and whitespace-only strings, trim whitespace, convert to lowercase, and remove duplicates
        // Preserve order of first occurrence
        var seen = Set<String>()
        let filteredTags =
            newTags
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .filter { seen.insert($0).inserted }  // Remove duplicates while preserving order

        // Check if tags actually changed
        let tagsChanged = Set(oldTags) != Set(filteredTags)

        // Always update the string (even if same, to normalize formatting)
        allTagsString = filteredTags.joined(separator: ",")

        // Only update timestamp and create comments if tags actually changed
        if tagsChanged {
            changed = Date.now

            if createComments && comments != nil {
                // Add comments for new tags
                filteredTags.filter { !oldTags.contains($0) }.forEach {
                    addComment(text: "Added tag: \($0)", icon: imgTag)
                }

                // Add comments for removed tags
                oldTags.filter { !filteredTags.contains($0) }.forEach {
                    addComment(text: "Removed tag: \($0)", icon: imgTag)
                }
            }
        }
    }

    public func addTag(_ newTag: String) {
        var newTags = self.tags
        newTags.append(newTag)
        updateTags(newTags, createComments: true)
        assert(self.tags.contains(newTag.lowercased()))
    }

    public func removeTag(_ oldTag: String) {
        var newTags = self.tags
        newTags.removeAll { $0 == oldTag.lowercased() }
        updateTags(newTags, createComments: true)
        assert(!self.tags.contains(oldTag.lowercased()))
    }

    public var isEmpty: Bool {
        return (title.isEmpty || title == emptyTaskTitle) && (details.isEmpty || details == emptyTaskDetails)
            && url.isEmpty
    }

    public var isOpen: Bool {
        return state == .open
    }

    public var isPriority: Bool {
        return state == .priority
    }

    public var isOpenOrPriority: Bool {
        return state == .open || state == .priority
    }

    public var isClosed: Bool {
        return state == .closed
    }

    public var isActive: Bool {
        return [.open, .priority, .pendingResponse].contains(self.state)
    }

    public var canBeMadePriority: Bool {
        return [.open, .pendingResponse].contains(self.state)
    }

    public var canBeClosed: Bool {
        return [.open, .priority, .pendingResponse, .dead].contains(self.state)
    }

    public var canBeMovedToOpen: Bool {
        return self.state != .open
    }

    public var canBeMovedToPendingResponse: Bool {
        return self.state != .pendingResponse
    }

    public var canBeTouched: Bool {
        return [.pendingResponse, .open, .priority, .dead].contains(self.state)
    }

    public var canBeDeleted: Bool {
        return [.closed, .dead].contains(self.state)
    }

    public var isDead: Bool {
        return state == .dead
    }

    public var isPending: Bool {
        return state == .pendingResponse
    }

    @discardableResult public func addComment(text: String, icon: String? = nil, state: TaskItemState? = nil)
        -> TaskItem
    {
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

    public func closeTask() {
        if _state != .closed {
            setState(.closed)
            addComment(text: "closed this task on \(Date.now)", icon: imgClosed, state: .closed)
        }
    }

    public func reOpenTask() {
        if _state != .open {
            setState(.open)
            addComment(text: "Reopened this Task.", icon: imgOpen, state: .open)
        }
    }
    public func graveyard() {
        if _state != .dead {
            setState(.dead)
            addComment(text: "Moved task to the Graveyard of not needed tasks.", icon: imgGraveyard, state: .dead)
        }
    }

    public func makePriority() {
        if _state != .priority {
            setState(.priority)
            addComment(text: "Turned into a priority.", icon: imgPriority, state: .priority)
        }
    }

    // MARK: - Explicit Setters (replace didSet handlers)

    public func setTitle(_ newTitle: String) {
        guard _title != newTitle else { return }
        _title = newTitle
        changed = Date.now
    }

    public func setDetails(_ newDetails: String) {
        guard _details != newDetails else { return }
        _details = newDetails
        changed = Date.now
    }

    public func setState(_ newState: TaskItemState) {
        guard _state != newState else { return }
        _state = newState
        changed = Date.now

        if newState == .closed {
            closed = Date.now
        } else {
            closed = nil
        }

        if comments != nil {
            addComment(text: "Changed state to: \(newState)", icon: imgStateChange)
        }
    }

    public func setUrl(_ newUrl: String) {
        guard _url != newUrl else { return }
        _url = newUrl
        changed = Date.now
    }

    public func setDueDate(_ newDueDate: Date?) {
        guard dueDate != newDueDate else { return }
        dueDate = newDueDate
        changed = Date.now
    }

    public func setTags(_ newTags: [String]) {
        let lowercaseTags = newTags.map { $0.lowercased() }
        guard allTagsString != lowercaseTags.joined(separator: ",") else { return }

        let oldTags = Set(tags)
        let newTagsSet = Set(lowercaseTags)

        allTagsString = lowercaseTags.joined(separator: ",")
        changed = Date.now

        // Add comments for tag changes
        let added = newTagsSet.subtracting(oldTags)
        let removed = oldTags.subtracting(newTagsSet)

        for tag in added where !tag.isEmpty {
            addComment(text: "Added tag: \(tag)", icon: imgTag)
        }
        for tag in removed where !tag.isEmpty {
            addComment(text: "Removed tag: \(tag)", icon: imgTag)
        }
    }

    public func setEstimatedMinutes(_ newMinutes: Int) {
        guard estimatedMinutes != newMinutes else { return }
        estimatedMinutes = newMinutes
        changed = Date.now
    }

    public func dueUntil(date: Date) -> Bool {
        if let due {
            return due <= date
        }
        return false
    }

    public func touch() {
        if _state == .open {
            addComment(text: "You 'touched' this task.", icon: imgTouch)
        } else {
            reOpenTask()
        }
    }

    /// only use for test cases
    public func setChangedDate(_ date: Date) {
        changed = date
    }

    public func pending() {
        if _state != .pendingResponse {
            setState(.pendingResponse)
            addComment(
                text: "You did your part. Closure is pending a response.", icon: imgPendingResponse,
                state: .pendingResponse)
        }
    }

    public func purgeableStoredBytes(at date: Date = Date()) -> Int {
        return attachments?.reduce(0) { $0 + ($1.isDueForPurge(at: date) ? $1.storedBytes : 0) } ?? 0
    }
    public var totalStoredBytes: Int { attachments?.reduce(0) { $0 + $1.storedBytes } ?? 0 }  // current storage
    public var totalOriginalBytes: Int { attachments?.reduce(0) { $0 + $1.byteSize } ?? 0 }  // original sizes

    public var isUnchanged: Bool {
        return isTitleEmpty && isDetailsEmpty && url.isEmpty && !hasAttachments
    }

    public var isTitleEmpty: Bool {
        return title.isEmpty || title == emptyTaskTitle
    }

    public var isDetailsEmpty: Bool {
        return details.isEmpty || details == emptyTaskDetails
    }

    public var hasAttachments: Bool {
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
    public var tags: Set<String> {
        var result = Set<String>()
        for t in self {
            result.formUnion(t.tags)
        }
        for t in result where t.isEmpty {
            result.remove(t)
        }
        return result
    }

    public var activeTags: Set<String> {
        var result = Set<String>()
        for t in self where !t.tags.isEmpty && t.isActive {
            result.formUnion(t.tags)
        }
        result.formUnion(["work", "private"])
        return result
    }

}
