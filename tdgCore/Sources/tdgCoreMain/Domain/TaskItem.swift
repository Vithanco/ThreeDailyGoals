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
        updateTags(other.tags)
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

    public func updateTags(_ newTags: [String], createComments: Bool = true) {
        func normalize(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let oldRaw = self.tags
        var seenOld = Set<String>()
        let oldNormOrdered =
            oldRaw
            .map(normalize)
            .filter { !$0.isEmpty && seenOld.insert($0).inserted }

        var seenNew = Set<String>()
        let newNormOrdered =
            newTags
            .map(normalize)
            .filter { !$0.isEmpty && seenNew.insert($0).inserted }

        allTagsString = newNormOrdered.joined(separator: ",")

        let oldSet = Set(oldNormOrdered)
        let newSet = Set(newNormOrdered)
        guard oldSet != newSet else { return }

        changed = Date.now

        if createComments && comments != nil {
            let added = newSet.subtracting(oldSet)
            let removed = oldSet.subtracting(newSet)

            for t in newNormOrdered where added.contains(t) {
                addComment(text: "Added tag: \(t)", icon: imgTag)
            }
            for t in oldNormOrdered where removed.contains(t) {
                addComment(text: "Removed tag: \(t)", icon: imgTag)
            }
        }
    }

    public func addTag(_ newTag: String) {
        let toBeAdded = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var newTags = self.tags
        newTags.append(toBeAdded)
        updateTags(newTags, createComments: true)
        assert(self.tags.contains(toBeAdded))
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

    public func setEstimatedMinutes(_ newMinutes: Int) {
        guard estimatedMinutes != newMinutes else { return }
        estimatedMinutes = newMinutes
        changed = Date.now
    }

    public func setCalendarEventId(_ newEventId: String?) {
        guard eventId != newEventId else { return }
        eventId = newEventId
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
        result.formUnion(standardTags)
        return result
    }

}

// MARK: - Energy-Effort Matrix Extensions

extension TaskItem {

    /// Check if task has both Energy-Effort dimensions set
    public var hasCompleteEnergyEffortTags: Bool {
        let taskTags = Set(self.tags)
        let hasEnergy = taskTags.contains("high-energy") || taskTags.contains("low-energy")
        let hasSize = taskTags.contains("big-task") || taskTags.contains("small-task")
        return hasEnergy && hasSize
    }

    /// Apply Energy-Effort Matrix tags to the task by removing old ones and adding new ones
    public func applyEnergyEffortTags(energyTag: String, effortTag: String) {
        // Remove any existing Energy-Effort Matrix tags
        var currentTags = self.tags.filter { tag in
            !["high-energy", "low-energy", "big-task", "small-task"].contains(tag)
        }

        // Add new quadrant tags
        currentTags.append(energyTag)
        currentTags.append(effortTag)

        // Update tags
        self.tags = currentTags
    }
}
