//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import CloudKit
import CoreData
import Foundation
import os
import SwiftData
import SwiftUI
import TagKit
 
private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: TaskManagerViewModel.self)
)

@Observable
class ListViewModel {
    var section: TaskSection
    var list: [TaskItem]
    
    init(section: TaskSection, list: [TaskItem]) {
        self.section = section
        self.list = list
    }
}

struct Choice {
    let existing: TaskItem
    let new: TaskItem
}

enum DialogState: String {
    case inform
    case currentPriorities
    case pending
    case dueDate
    case review
    case plan
}

extension TagCapsuleStyle.Border: @unchecked Sendable {
    static let none: TagCapsuleStyle.Border = .init(
        color: .clear,
        width: 0
    )
}

extension Notification: @unchecked Sendable {}

@Observable
final class TaskManagerViewModel {
    private var notificationTask: Task<Void, Never>?
    let timer: ReviewTimer = .init()
    let modelContext: Storage
    private(set) var items = [TaskItem]()
    var isTesting: Bool = false
    
    var stateOfReview: DialogState = .inform
    
    // Import/Export
    public var showImportDialog: Bool = false
    public var showExportDialog: Bool = false
    var jsonExportDoc: JSONWriteOnlyDoc?
    
    var preferences: CloudPreferences
    
    var accentColor: Color {
        return preferences.accentColor
    }
    
    func select(which: TaskItemState, item: TaskItem?) {
        withAnimation {
            whichList = which
            selectedItem = item
        }
    }
    
    /// used in Content view of NavigationSplitView
    var whichList = TaskItemState.open
    
    /// used in Detail View of NavigationSplitView
    var selectedItem: TaskItem?
    
    var showItem: Bool
    var canUndo = false
    var canRedo = false
    
    var showReviewDialog: Bool = false
    var showSettingsDialog: Bool = false
    var showMissingReviewAlert: Bool = false
    var showSelectDuringImportDialog: Bool = false
    var showNewItemNameDialog: Bool = false
    var selectDuringImport: [Choice] = []
    
    var streakText: String = ""
    
    var lists: [TaskItemState: [TaskItem]] = [:]
    
    // for user messages
    var showInfoMessage: Bool = false
    var infoMessage: String = "(invalid)"
    
    var selectedTags: [String] = []
    var missingTagStyle: TagCapsuleStyle {
        TagCapsuleStyle(foregroundColor: .white, backgroundColor: .gray, border: .none, padding: .init(top: 1, leading: 3, bottom: 1, trailing: 3))
    }

    var selectedTagStyle: TagCapsuleStyle {
        TagCapsuleStyle(foregroundColor: accentColor.readableTextColor, backgroundColor: accentColor, border: .none, padding: .init(top: 1, leading: 3, bottom: 1, trailing: 3))
    }
    
    func finishDialog() {
        showInfoMessage = false
    }
    
    init(modelContext: Storage, preferences: CloudPreferences, isTesting: Bool = false) {
        self.modelContext = modelContext
        self.preferences = preferences
        self.isTesting = isTesting
        showItem = false
        for c in TaskItemState.allCases {
            lists[c] = []
        }
        callFetch()
        
        Task { [weak self] in
            let center = NotificationCenter.default
            for await notification in center.notifications(named: NSPersistentCloudKitContainer.eventChangedNotification) {
                guard let self else { break }
                if let userInfo = notification.userInfo {
                    Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: TaskManagerViewModel.self)).debug("Event: \(userInfo.debugDescription)")
                    if let event = userInfo["event"] as? NSPersistentCloudKitContainer.Event {
                        if event.type == .import && event.endDate != nil && event.succeeded {
                            Logger(
                                subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TaskManagerViewModel.self)
                            ).debug("received: \(event.debugDescription)")
                            //                              //  logger.debug("update my list of Tasks")
//                            weak var receiver = self
//                            await receiver?.fetchData()
                        }
                    }
                }
            }
        }
        preferences.onChange = onPreferencesChange
        setupReviewNotification()
    }
        
    deinit {
        notificationTask?.cancel()
    }

    func addSamples() -> Self {
        let lastWeek1 = TaskItem(title: "3 days ago", changedDate: getDate(daysPrior: 3))
        let lastWeek2 = TaskItem(title: "5 days ago", changedDate: getDate(daysPrior: 5))
        let lastMonth1 = TaskItem(title: "11 days ago", changedDate: getDate(daysPrior: 11))
        let lastMonth2 = TaskItem(title: "22 days ago", changedDate: getDate(daysPrior: 22))
        let older1 = TaskItem(title: "31 days ago", changedDate: getDate(daysPrior: 31))
        let older2 = TaskItem(title: "101 days ago", changedDate: getDate(daysPrior: 101))
        move(task: lastWeek1, to: .priority)
        modelContext.insert(lastWeek1)
        modelContext.insert(lastWeek2)
        modelContext.insert(lastMonth1)
        modelContext.insert(lastMonth2)
        modelContext.insert(older1)
        modelContext.insert(older2)
        
        try? modelContext.save()
        callFetch()
        return self
    }
    
    //    func clear() {
    //        try? modelContext.delete(model: TaskItem.self)
    //        try? modelContext.save()
    //        fetchData()
    //    }
    //
    fileprivate func sortList(_ t: TaskItemState) {
        lists[t]?.sort(by: t.sorter)
    }
    
    fileprivate func ensureEveryItemHasAUniqueUuid() {
        var allUuids: Set<UUID> = []
        for i in items {
            if allUuids.contains(i.uuid) {
                i.uuid = UUID()
            } else {
                allUuids.insert(i.uuid)
            }
        }
        assert(Set(items.map(\.uuid)).count == items.count, "Duplicate UUIDs: \(items.count - Set(items.map(\.uuid)).count)")
    }
    
    func fetchData() {
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.changed, order: .forward)])
            let items = try modelContext.fetch(descriptor)
            self.items = items
            logger.info("fetched \(items.count) tasks from central store")
            for t in lists.keys {
                lists[t]?.removeAll(keepingCapacity: true)
            }
            for item in items {
                lists[item.state]?.append(item)
            }
            for t in lists.keys {
                sortList(t)
            }
            ensureEveryItemHasAUniqueUuid()
            updateUndoRedoStatus()

        } catch {
            print("Fetch failed")
        }
    }
    
    @discardableResult func addItem(title: String = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open) -> TaskItem {
        let newItem = TaskItem(title: title, details: details, changedDate: changedDate, state: state)
        addItem(item: newItem)
        return newItem
    }
    
    public var isProductionEnvironment: Bool {
        return CKContainer.isProductionEnvironment
    }
    
    func addItem(item: TaskItem) {
        modelContext.insert(item)
        if let comments = item.comments {
            for c in comments {
                modelContext.insert(c)
            }
        }
        items.append(item)
        lists[item.state]?.append(item)
        sortList(item.state)
        modelContext.processPendingChanges()
        updateUndoRedoStatus()
    }
    
    fileprivate func select(_ newItem: TaskItem) {
#if os(macOS)
        select(which: newItem.state, item: newItem)
#endif
#if os(iOS)
        selectedItem = newItem
        showItem = true
#endif
    }
    
    func addNewItem() {
        showNewItemNameDialog = true
    }
    
    @discardableResult func addAndSelect(title: String = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open) -> TaskItem {
        let newItem = addItem(title: title, details: details, changedDate: changedDate, state: state)
        select(newItem)
        return newItem
    }
    
    fileprivate func callFetch() {
//        Task {
//            do {
                fetchData()
//            }
//        }
    }
    
    func undo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.undo()
            modelContext.processPendingChanges()
            callFetch()
        }
    }
    
    func redo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.redo()
            modelContext.processPendingChanges()
            callFetch()
        }
    }
    
    func updateUndoRedoStatus() {
        modelContext.processPendingChanges()
        modelContext.processPendingChanges()
        canUndo = modelContext.canUndo
        canRedo = modelContext.canRedo
        
        let next = nextRegularReviewTime
        let today = preferences.lastReview.isToday ? "Done" : stdOnlyTimeFormat.format(next)
        streakText = "Streak: \(preferences.daysOfReview), today: \(today)" // - Time:
    }
    
    func findTask(withID: String) -> TaskItem? {
        let result = items.first(where: { $0.id == withID })
        logger.debug("found Task '\(result != nil)' for ID: \(withID)")
        return result
    }
    
    func findTask(withUuidString: String) -> TaskItem? {
        if let uuid = UUID(uuidString: withUuidString) {
            return findTask(withID: uuid.uuidString)
        }
        return nil
    }
    
    func touch(task: TaskItem) {
        task.touch()
        updateUndoRedoStatus()
    }
    
    func delete(task: TaskItem) {
        withAnimation {
            modelContext.beginUndoGrouping()
            lists[task.state]?.removeObject(task)
            if let index = items.firstIndex(of: task) {
                items.remove(at: index)
            }
            for c in task.comments ?? [] {
                modelContext.delete(c)
            }
            modelContext.delete(task)
            modelContext.endUndoGrouping()
            updateUndoRedoStatus()
            selectedItem = currentList.first
        }
    }
    
    /// updating priorities to key value store, so that we show them in the Widget
    fileprivate func updatePriorities() {
        if let prioTasks = lists[.priority] {
            let prios = prioTasks.count
            for i in 0..<prios {
                preferences.setPriority(nr: i+1, value: prioTasks[i].title)
            }
            if prios < 5 {
                for i in prios ... 4 {
                    preferences.setPriority(nr: i+1, value: "")
                }
            }
        }
    }
    
    func move(task: TaskItem, to: TaskItemState) {
        if task.state == to {
            return // nothing to be done
        }
        let moveFromPriority = task.state == .priority
        lists[task.state]?.removeObject(task)
        switch to {
        case .open:
            task.reOpenTask()
        case .closed:
            task.closeTask()
        case .dead:
            task.graveyard()
        case .priority:
            task.makePriority()
        case .pendingResponse:
            task.pending()
        }
        lists[to]?.append(task)
        sortList(to)
        
        // Did it touch priorities (in or out)? If so, update priorities
        if to == .priority || moveFromPriority {
            updatePriorities()
        }
        updateUndoRedoStatus()
    }

    func resetAccentColor() {
        preferences.resetAccentColor()
    }
    
    @discardableResult func killOldTasks(expireAfter: Int? = nil) -> Int {
        var result = 0
        let expiryDays = expireAfter ?? preferences.expiryAfter
        let expireData = getDate(daysPrior: expiryDays)
        result += killOldTasks(expiryDate: expireData, whichList: .open)
        result += killOldTasks(expiryDate: expireData, whichList: .priority)
        result += killOldTasks(expiryDate: expireData, whichList: .pendingResponse)
        logger.info("killed \(result) tasks")
        return result
    }
    
    func killOldTasks(expiryDate: Date, whichList: TaskItemState) -> Int {
        let theList = list(which: whichList)
        var result = 0
        for task in theList {
            if task.changed < expiryDate {
                move(task: task, to: .dead)
                result += 1
            }
        }
        return result
    }
    
    func remove(item: TaskItem) {
        items.removeObject(item)
        lists[item.state]?.removeObject(item)
        modelContext.delete(item)
    }
    
    func showPreferences() {
        showSettingsDialog = true
    }
    
    func removeItem(withID: String) {
        if let item = items.first(where: { $0.id == withID }) {
            remove(item: item)
        }
    }
}

extension TaskManagerViewModel {
    func list(which: TaskItemState) -> [TaskItem] {
        guard let result = lists[which] else {
            logger.fault("couldn't retrieve list \(which) from lists")
            return []
        }
        return result
    }
    
    var currentList: [TaskItem] {
        return list(which: whichList)
    }
}

//
// extension TaskManagerViewModel {
//    internal var undoManager: UndoManager? {
//        return modelContext.undoManager
//    }
// }

extension TaskManagerViewModel {
    // for testing purposes
    var hasUndoManager: Bool {
        return modelContext.undoManager != nil
    }
    
    func beginUndoGrouping() {
        modelContext.beginUndoGrouping()
        updateUndoRedoStatus()
    }
    
    func endUndoGrouping() {
        modelContext.endUndoGrouping()
        updateUndoRedoStatus()
    }
}

@MainActor
func dummyViewModel(loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil) -> TaskManagerViewModel {
    let loader = loader ?? loadStdItems
    return TaskManagerViewModel(modelContext: TestStorage(loader: loader), preferences: preferences ?? dummyPreferences(), isTesting: true)
}

func loadStdItems() -> [TaskItem] {
    var result: [TaskItem] = []
    let theGoal = result.add(title: "Read 'The Goal' by Goldratt", changedDate: Date.now.addingTimeInterval(-1 * Seconds.fiveMin))
    theGoal.details = "It is the book that introduced the fundamentals for 'Theory of Constraints'"
    theGoal.url = "https://www.goodreads.com/book/show/113934.The_Goal"
    theGoal.dueDate = getDate(inDays: 2)
    result.add(title: "Try out Concept Maps", changedDate: getDate(daysPrior: 3), state: .priority, tags: ["CMaps"])
    result.add(title: "Read about Systems Thinking", changedDate: getDate(daysPrior: 5), tags: ["toRead"])
    result.add(title: "Transfer tasks from old task manager into this one", changedDate: getDate(daysPrior: 11), state: .open)
    let lastMonth2 = result.add(title: "Read about Structured Visual Thinking", changedDate: getDate(daysPrior: 22), state: .open, tags: ["toRead"])
    lastMonth2.url = "https://vithanco.com"
    result.add(title: "Contact Vithanco Author regarding new map style", changedDate: getDate(daysPrior: 3), state: .pendingResponse)
    result.add(title: "Read this", changedDate: getDate(daysPrior: 31), state: .dead)
    result.add(title: "Read this about Agile vs Waterfall", changedDate: getDate(daysPrior: 101), state: .dead)
    result.add(title: "Request Parking Permission", changedDate: getDate(inDays: 3), state: .pendingResponse)
    result.add(title: "Tax Declaration", changedDate: getDate(inDays: 30), state: .open, dueDate: getDate(inDays: 2))
    for i in 32..<200 {
        result.add(title: "Dead Task \(i)", changedDate: getDate(daysPrior: i), state: .dead)
    }
    return result
}

extension Sequence where Element: TaskItem {
    var tags: Set<String> {
        var result = Set<String>()
        for t in self {
            result.formUnion(t._tags)
        }
        return result
    }
}

extension TaskManagerViewModel {
    var allTags: Set<String> {
        var result = items.tags
        result.formUnion(["work", "private"])
        return result
    }

    var activeTags: Set<String> {
        var result = Set<String>()
        for t in items {
            if !t.tags.isEmpty && t.isActive {
                result.formUnion(t.tags)
            }
        }
        result.formUnion(["work", "private"])
        return result
    }

    func statsForTags(tag: String) -> [TaskItemState: Int] {
        var result: [TaskItemState: Int] = [:]
        for t in TaskItemState.allCases {
            result[t] = statsForTags(tag: tag, which: t)
        }
        return result
    }

    func statsForTags(tag: String, which: TaskItemState) -> Int {
        let list = self.list(which: which)
        var result = 0
        for item in list {
            if item.tags.contains(tag) {
                result += 1
            }
        }
        return result
    }

    func exchangeTag(from: String, to: String) {
        for item in items {
            item.tags = item.tags.map { $0 == from ? to : $0 }
        }
    }

    func delete(tag: String) {
        if tag.isEmpty {
            return
        }
        for item in items {
            item.tags = item.tags.filter { $0 != tag }
        }
    }
}
