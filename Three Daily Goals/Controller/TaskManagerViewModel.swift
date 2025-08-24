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
        dataManager.mergeDataFromCentralStorage()

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
        dataManager.createSampleData()
        dataManager.mergeDataFromCentralStorage()
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



    @MainActor
    func mergeDataFromCentralStorage() {
        dataManager.mergeDataFromCentralStorage()
        updateUndoRedoStatus()
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
    func updateUndoRedoStatus() {
        dataManager.updateUndoRedoStatus()
        canUndo = dataManager.canUndo
        canRedo = dataManager.canRedo

        let next = nextRegularCompassCheckTime
        let _ = preferences.didCompassCheckToday ? "Done" : stdOnlyTimeFormat.format(next)
    }



    func touch(task: TaskItem) {
        dataManager.touch(task: task)
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


}

extension TaskManagerViewModel {
    var currentList: [TaskItem] {
        return dataManager.list(which: whichList)
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



