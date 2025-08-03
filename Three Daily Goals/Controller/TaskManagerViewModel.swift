//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import CloudKit
import CoreData
import Foundation
import SwiftData
import SwiftUI
import TagKit
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: TaskManagerViewModel.self)
)

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

enum SupportedOS {
    case iOS
    case macOS
    case ipadOS
}

extension TagCapsuleStyle.Border: @unchecked Sendable {
    static let none: TagCapsuleStyle.Border = .init(
        color: .clear,
        width: 0
    )
}

//extension Notification: @unchecked Sendable {}

@MainActor
@Observable
final class TaskManagerViewModel {
    private var notificationTask: Task<Void, Never>? {
        willSet {
            notificationTask?.cancel()
        }
    }
    let timer: CompassCheckTimer = .init()
    let modelContext: Storage
    private(set) var items = [TaskItem]()
    var isTesting: Bool = false

    var stateOfCompassCheck: DialogState = .inform

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

    var os: SupportedOS {
        #if os(iOS)
            if isLargeDevice {
                return .ipadOS
            }
            return .iOS
        #elseif os(macOS)
            return .macOS
        #endif
    }

    var showCompassCheckDialog: Bool = false
    var showSettingsDialog: Bool = false
    var showMissingCompassCheckAlert: Bool = false
    var showSelectDuringImportDialog: Bool = false
    var showNewItemNameDialog: Bool = false
    var selectDuringImport: [Choice] = []

    var lists: [TaskItemState: [TaskItem]] = [:]

    // for user messages
    var showInfoMessage: Bool = false
    var infoMessage: String = "(invalid)"

    var selectedTags: [String] = []
    var missingTagStyle: TagCapsuleStyle {
        TagCapsuleStyle(
            foregroundColor: .white,
            backgroundColor: .gray,
            border: .none,
            padding: .init(top: 1, leading: 3, bottom: 1, trailing: 3)
        )
    }

    var selectedTagStyle: TagCapsuleStyle {
        TagCapsuleStyle(
            foregroundColor: accentColor.readableTextColor,
            backgroundColor: accentColor,
            border: .none,
            padding: .init(top: 1, leading: 3, bottom: 1, trailing: 3)
        )
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
            for await notification in center.notifications(
                named: NSPersistentCloudKitContainer.eventChangedNotification)
            {
                guard let self else { break }
                if let userInfo = notification.userInfo {
                    if let event = userInfo["event"] as? NSPersistentCloudKitContainer.Event {
                        if event.type == .import && event.endDate != nil && event.succeeded {
                            if !modelContext.hasChanges {
                                mergeDataFromCentralStorage()
                            } else {
                                do {
                                    try modelContext.save()
                                    logger.debug("Saved pending changes, now merging from central storage")
                                    mergeDataFromCentralStorage()
                                } catch {
                                    logger.error("Failed to save pending changes: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
        preferences.onChange = onPreferencesChange
        setupCompassCheckNotification()
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
        assert(
            Set(items.map(\.uuid)).count == items.count,
            "Duplicate UUIDs: \(items.count - Set(items.map(\.uuid)).count)")
    }

    @MainActor
    func mergeDataFromCentralStorage() {
        modelContext.processPendingChanges()
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [
                SortDescriptor(\.changed, order: .forward)
            ])
            let items = try modelContext.fetch(descriptor)
            let fetchedItems = try modelContext.fetch(descriptor)
            let (added, updated) = mergeItems(fetchedItems)

            logger.info(
                "fetched \(items.count) tasks from central store, added \(added), updated \(updated)")
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

    private func mergeItems(_ fetchedItems: [TaskItem]) -> (Int, Int) {
        var itemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        var addedCount = 0
        var updatedCount = 0

        for fetchedItem in fetchedItems {
            if let existingItem = itemsById[fetchedItem.id] {
                if fetchedItem.changed > existingItem.changed {
                    existingItem.updateFrom(fetchedItem)
                    updatedCount = updatedCount + 1
                }
            } else {
                items.append(fetchedItem)
                itemsById[fetchedItem.id] = fetchedItem
                addedCount = addedCount + 1
            }
        }
        return (addedCount, updatedCount)
    }

    @discardableResult func addItem(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let newItem = TaskItem(title: title, details: details, changedDate: changedDate, state: state)
        addItem(item: newItem)
        return newItem
    }

    public var isProductionEnvironment: Bool {
        return CKContainer.isProductionEnvironment
    }

    func addItem(item: TaskItem) {
        if item.isEmpty {
            return
        }
        modelContext.insert(item)
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

    @discardableResult func addAndSelect(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let newItem = addItem(title: title, details: details, changedDate: changedDate, state: state)
        select(newItem)
        return newItem
    }

    @MainActor
    fileprivate func callFetch() {
        mergeDataFromCentralStorage()
    }

    @MainActor
    func undo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.undo()
            modelContext.processPendingChanges()
            callFetch()
        }
    }

    @MainActor
    func redo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.redo()
            modelContext.processPendingChanges()
            callFetch()
        }
    }

    @MainActor
    func updateUndoRedoStatus() {
        modelContext.processPendingChanges()
        modelContext.processPendingChanges()
        canUndo = modelContext.canUndo
        canRedo = modelContext.canRedo

        let next = nextRegularCompassCheckTime
        let today = preferences.didCompassCheckToday ? "Done" : stdOnlyTimeFormat.format(next)
    }

    func findTask(withID: String) -> TaskItem? {
        let result = items.first(where: { $0.id == withID })
        //    logger.debug("found Task '\(result != nil)' for ID: \(withID)")
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
                preferences.setPriority(nr: i + 1, value: prioTasks[i].title)
            }
            if prios < 5 {
                for i in prios...4 {
                    preferences.setPriority(nr: i + 1, value: "")
                }
            }
        }
    }

    func move(task: TaskItem, to: TaskItemState) {
        if task.state == to {
            return  // nothing to be done
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
        for task in theList where task.changed < expiryDate {
            move(task: task, to: .dead)
            result += 1
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
func dummyViewModel(loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil)
    -> TaskManagerViewModel
{
    let testStorage = loader == nil ? TestStorage() : TestStorage(loader: loader!)
    return TaskManagerViewModel(
        modelContext: testStorage, preferences: preferences ?? dummyPreferences(), isTesting: true)
}

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

extension TaskManagerViewModel {
    var allTags: Set<String> {
        var result = items.tags
        result.formUnion(["work", "private"])
        return result
    }

    var activeTags: Set<String> {
        var result = Set<String>()
        for t in items where !t.tags.isEmpty && t.isActive {
            result.formUnion(t.tags)
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
        for item in list where item.tags.contains(tag) {
            result += 1
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
