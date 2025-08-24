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
    var isTesting: Bool = false

    var stateOfCompassCheck: DialogState = .inform

    // Import/Export
    public var showImportDialog: Bool {
        get { uiState.showImportDialog }
        set { uiState.showImportDialog = newValue }
    }
    
    public var showExportDialog: Bool {
        get { uiState.showExportDialog }
        set { uiState.showExportDialog = newValue }
    }
    
    var jsonExportDoc: JSONWriteOnlyDoc?

    var preferences: CloudPreferences
    var uiState: UIStateManager
    var dataManager: DataManager

    var accentColor: Color {
        return preferences.accentColor
    }



    /// used in Content view of NavigationSplitView
    var whichList: TaskItemState {
        get { uiState.whichList }
        set { uiState.whichList = newValue }
    }

    /// used in Detail View of NavigationSplitView
    var selectedItem: TaskItem? {
        get { uiState.selectedItem }
        set { uiState.selectedItem = newValue }
    }

    var showItem: Bool {
        get { uiState.showItem }
        set { uiState.showItem = newValue }
    }
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







    func finishDialog() {
        uiState.finishDialog()
    }

    init(modelContext: Storage, preferences: CloudPreferences, uiState: UIStateManager, isTesting: Bool = false) {
        self.preferences = preferences
        self.uiState = uiState
        self.dataManager = DataManager(modelContext: modelContext)
        self.isTesting = isTesting
        
        // Load initial data
        dataManager.loadData()
        showItem = false
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
                            logger.debug("CloudKit import succeeded, processing changes")
                            if !dataManager.hasChanges {
                                mergeDataFromCentralStorage()
                            } else {
                                do {
                                    try dataManager.save()
                                    logger.debug("Saved pending changes, now merging from central storage")
                                    mergeDataFromCentralStorage()
                                } catch {
                                    logger.error("Failed to save pending changes: \(error)")
                                }
                            }
                        } else if event.type == .export && event.endDate != nil && event.succeeded {
                            logger.debug("CloudKit export succeeded")
                        } else if event.type == .setup && event.endDate != nil && event.succeeded {
                            logger.debug("CloudKit setup succeeded")
                        } else if let error = event.error {
                            logger.error("CloudKit event failed: \(error)")
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
        dataManager.createTask(title: lastWeek1.title, state: lastWeek1.state)
        dataManager.createTask(title: lastWeek2.title, state: lastWeek2.state)
        dataManager.createTask(title: lastMonth1.title, state: lastMonth1.state)
        dataManager.createTask(title: lastMonth2.title, state: lastMonth2.state)
        dataManager.createTask(title: older1.title, state: older1.state)
        dataManager.createTask(title: older2.title, state: older2.state)

        callFetch()
        return self
    }

    //    func clear() {
    //        try? modelContext.delete(model: TaskItem.self)
    //        try? modelContext.save()
    //        fetchData()
    //    }
    //
    fileprivate     func sortList(_ t: TaskItemState) {
        dataManager.lists[t]?.sort(by: t.sorter)
    }

    fileprivate func ensureEveryItemHasAUniqueUuid() {
        var _: Set<UUID> = []
        // This is now handled by DataManager
        dataManager.loadData()
    }

    @MainActor
    func mergeDataFromCentralStorage() {
        dataManager.processPendingChanges()
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [
                SortDescriptor(\.changed, order: .forward)
            ])
            let fetchedItems = try dataManager.modelContext.fetch(descriptor)
            let (added, updated) = mergeItems(fetchedItems)

            logger.info(
                "fetched \(fetchedItems.count) tasks from central store, added \(added), updated \(updated)")
            // This is now handled by DataManager
            dataManager.organizeLists()
            ensureEveryItemHasAUniqueUuid()
            updateUndoRedoStatus()

        } catch {
            print("Fetch failed")
        }
    }

    private func mergeItems(_ fetchedItems: [TaskItem]) -> (Int, Int) {
        var seenIDs = Set<UUID>()
        let adjustedItems = fetchedItems.map { item -> TaskItem in
            if seenIDs.contains(item.uuid) {
                let newItem = item
                newItem.uuid = UUID()
                return newItem
            }
            seenIDs.insert(item.uuid)
            return item
        }
        
        var addedCount = 0
        var updatedCount = 0

        // Create a dictionary of existing items by ID for quick lookup
        var existingItemsById = Dictionary(uniqueKeysWithValues: dataManager.items.map { ($0.id, $0) })

        for fetchedItem in adjustedItems {
            if let existingItem = existingItemsById[fetchedItem.id] {
                // Item exists, check if it needs updating
                if fetchedItem.changed > existingItem.changed {
                    existingItem.updateFrom(fetchedItem)
                    updatedCount = updatedCount + 1
                }
            } else {
                // New item, add it
                dataManager.items.append(fetchedItem)
                existingItemsById[fetchedItem.id] = fetchedItem
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
        dataManager.addExistingTask(item)
        updateUndoRedoStatus()
    }

    fileprivate func select(_ newItem: TaskItem) {
        #if os(macOS)
        uiState.select(which: newItem.state, item: newItem)
        #endif
        #if os(iOS)
            selectedItem = newItem
            showItem = true
        #endif
    }

    func addNewItem() {
        uiState.showNewItemNameDialog = true
    }

    @discardableResult func addAndSelect(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let newItem = addItem(title: title, details: details, changedDate: changedDate, state: state)
        // Find the saved item in the database to ensure we're selecting the correct object
        if let savedItem = dataManager.findTask(withUuidString: newItem.uuid.uuidString) {
            select(savedItem)
            return savedItem
        } else {
            select(newItem)
            return newItem
        }
    }

    @MainActor
    fileprivate func callFetch() {
        mergeDataFromCentralStorage()
    }

    @MainActor
    func undo() {
        withAnimation {
            dataManager.undo()
            callFetch()
        }
    }

    @MainActor
    func redo() {
        withAnimation {
            dataManager.redo()
            callFetch()
        }
    }

    @MainActor
    func updateUndoRedoStatus() {
        dataManager.processPendingChanges()
        dataManager.processPendingChanges()
        canUndo = dataManager.canUndo
        canRedo = dataManager.canRedo

        let next = nextRegularCompassCheckTime
        let _ = preferences.didCompassCheckToday ? "Done" : stdOnlyTimeFormat.format(next)
    }

    func findTask(withID: String) -> TaskItem? {
        return dataManager.findTask(withUuidString: withID)
    }

    func findTask(withUuidString: String) -> TaskItem? {
        return dataManager.findTask(withUuidString: withUuidString)
    }

    func touch(task: TaskItem) {
        task.touch()
        updateUndoRedoStatus()
    }

    func delete(task: TaskItem) {
        withAnimation {
            dataManager.beginUndoGrouping()
            dataManager.deleteTask(task)
            dataManager.endUndoGrouping()
            updateUndoRedoStatus()
            selectedItem = currentList.first
        }
    }

    /// updating priorities to key value store, so that we show them in the Widget
    fileprivate func updatePriorities() {
        if let prioTasks = dataManager.lists[.priority] {
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
        
        // Update the task state using DataManager
        dataManager.move(task: task, to: to)
        
        // Update local lists for UI consistency
        dataManager.lists[task.state]?.removeObject(task)
        dataManager.lists[to]?.append(task)
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
        dataManager.items.removeObject(item)
        dataManager.lists[item.state]?.removeObject(item)
        dataManager.deleteTask(item)
    }

    func showPreferences() {
        uiState.showSettingsDialog = true
    }

    func removeItem(withID: String) {
        if let item = dataManager.items.first(where: { $0.id == withID }) {
            remove(item: item)
        }
    }
}

extension TaskManagerViewModel {
    func list(which: TaskItemState) -> [TaskItem] {
        return dataManager.list(which: which)
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
        return dataManager.modelContext.undoManager != nil
    }

    func beginUndoGrouping() {
        dataManager.beginUndoGrouping()
        updateUndoRedoStatus()
    }

    func endUndoGrouping() {
        dataManager.endUndoGrouping()
        updateUndoRedoStatus()
    }
}

@MainActor
func dummyViewModel(loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil)
    -> TaskManagerViewModel
{
    let testStorage = loader == nil ? TestStorage() : TestStorage(loader: loader!)
    return TaskManagerViewModel(
        modelContext: testStorage, 
        preferences: preferences ?? dummyPreferences(), 
        uiState: UIStateManager(),
        isTesting: true)
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


    var activeTags: Set<String> {
        var result = dataManager.activeTags
        result.formUnion(["work", "private"])
        return result
    }
    
    var allTags: Set<String> {
        var result = Set<String>()
        for t in dataManager.items where !t.tags.isEmpty {
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
        for item in dataManager.items {
            item.tags = item.tags.map { $0 == from ? to : $0 }
        }
    }

    func delete(tag: String) {
        if tag.isEmpty {
            return
        }
        for item in dataManager.items {
            item.tags = item.tags.filter { $0 != tag }
        }
    }
}
