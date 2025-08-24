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
    var jsonExportDoc: JSONWriteOnlyDoc?

    var preferences: CloudPreferences
    var uiState: UIStateManager
    var dataManager: DataManager

    var accentColor: Color {
        return preferences.accentColor
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







    public var isProductionEnvironment: Bool {
        return CKContainer.isProductionEnvironment
    }

    init(modelContext: Storage, preferences: CloudPreferences, uiState: UIStateManager, isTesting: Bool = false) {
        self.preferences = preferences
        self.uiState = uiState
        self.dataManager = DataManager(modelContext: modelContext)
        self.isTesting = isTesting
        
        // Load initial data
        dataManager.loadData()
        uiState.showItem = false
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
                                dataManager.mergeDataFromCentralStorage()
                            } else {
                                do {
                                    try dataManager.save()
                                    logger.debug("Saved pending changes, now merging from central storage")
                                    dataManager.mergeDataFromCentralStorage()
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


    


    //    func clear() {
    //        try? modelContext.delete(model: TaskItem.self)
    //        try? modelContext.save()
    //        fetchData()
    //    }
    //




    @discardableResult func addAndSelect(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let item = dataManager.addAndFindItem(title: title, details: details, changedDate: changedDate, state: state)
        uiState.select(item)
        return item
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
        
        // Did it touch priorities (in or out)? If so, update priorities
        if to == .priority || moveFromPriority {
            updatePriorities()
        }
    }


}

extension TaskManagerViewModel {
    var currentList: [TaskItem] {
        return dataManager.list(which: uiState.whichList)
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



