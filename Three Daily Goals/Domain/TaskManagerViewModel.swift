//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import Foundation
import SwiftData
import SwiftUI
import os
import CoreData

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: TaskManagerViewModel.self)
)

@Observable
class ListViewModel {
    var sections: [TaskSection]
    var list: [TaskItem]
    
    init(sections: [TaskSection], list: [TaskItem]) {
        self.sections = sections
        self.list = list
    }
}


extension TaskItemState {
    var sections: [TaskSection] {
        switch self {
            case .open : return [secOpen]
            case .closed: return [secClosed]
            case .dead: return [secGraveyard]
            case .priority: return [secToday]
            case .pendingResponse: return [secPending]
        }
    }
}



@Observable
final class TaskManagerViewModel {
    private let modelContext: Storage
    private(set) var items = [TaskItem]()
    
    var preferences: Preferences
    
    var accentColor: Color {
        return preferences.accentColor
    }
    
    func select(which: TaskItemState, item: TaskItem?) {
        withAnimation {
            whichList = which
            selectedItem = item
        }
    }
    
    ///used in Content view of NavigationSplitView
    var whichList = TaskItemState.open
    
    /// used in Detail View of NavigationSplitView
    var selectedItem: TaskItem? = nil
    
    var showItem: Bool = false
    var canUndo = false
    var canRedo = false
    
    var showReviewDialog: Bool = false
    
    var openTasks: [TaskItem] = []
    var closedTasks: [TaskItem]  = []
    var deadTasks: [TaskItem]  = []
    var pendingTasks: [TaskItem]  = []
    var priorityTasks: [TaskItem]  = []
    
    var today: DailyTasks? = nil
    
    
    init(modelContext: Storage) {
        self.modelContext = modelContext
        preferences = loadPreferences(modelContext: modelContext)
        
        //        NotificationCenter.default.notifications(named: Notification.Name.NSManagedObjectContextObjectsDidChange)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notification(_ :)),
                                               name: .NSPersistentStoreRemoteChange,
                                               object: nil)
        fetchData()
//#if os(macOS)
        NotificationCenter.default.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: OperationQueue.main){(notification) in self.fetchData()}
//#endif
//#if os(iOS)
//        NotificationCenter.default.addObserver(forName: UIPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: OperationQueue.main){(notification) in self.fetchData()}
//        #endif
    }
    
    @objc func notification(_ notification: Foundation.Notification) {
        debugPrint(notification)
//        fetchData()
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
        fetchData()
        return self
    }
    
//    func clear() {
//        try? modelContext.delete(model: TaskItem.self)
//        try? modelContext.save()
//        fetchData()
//    }
//    
    func fetchData() {
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.changed, order: .forward)])
            items = try modelContext.fetch(descriptor)
            openTasks.removeAll()
            closedTasks.removeAll()
            pendingTasks.removeAll()
            deadTasks.removeAll()
            priorityTasks.removeAll()
            for item in items {
                switch item.state {
                    case .open: openTasks.append(item)
                    case .closed : closedTasks.append(item)
                    case .pendingResponse : pendingTasks.append(item)
                    case .dead: deadTasks.append(item)
                    case .priority: priorityTasks.append(item)
                }
            }
            openTasks.sort()
            closedTasks.sort()
            pendingTasks.sort()
            deadTasks.sort()
            priorityTasks.sort()
            updateUndoRedoStatus()
        } catch {
            print("Fetch failed")
        }
    }
    
    @discardableResult func addItem() -> TaskItem {
        let newItem = TaskItem()
        modelContext.insert(newItem)
        items.append(newItem)
        openTasks.append(newItem)
        modelContext.processPendingChanges()
        #if os(macOS)
        select(which: .open, item: newItem)
        #endif
#if os(iOS)
        selectedItem = newItem
        showItem = true
#endif
        updateUndoRedoStatus()
        return newItem
    }
    
    func undo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.undo()
            modelContext.processPendingChanges()
            fetchData()
        }
    }
    
    func redo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.redo()
            modelContext.processPendingChanges()
            fetchData()
        }
    }
    
    func updateUndoRedoStatus() {
        modelContext.processPendingChanges()
        modelContext.processPendingChanges()
        canUndo =  modelContext.canUndo
        canRedo =  modelContext.canRedo
    }
    
    func loadToday() {
//        today = loadPriorities(modelContext: modelContext)
        
    }
    
    func findTask(withID: String) -> TaskItem? {
        let result = items.first(where: {$0.id == withID})
        logger.debug("found Task '\(result != nil)' for ID: \(withID)")
        return result
    }
    
    func touch(task: TaskItem) {
        task.touch()
        updateUndoRedoStatus()
    }
    
    func delete(task: TaskItem) {
        withAnimation {
            modelContext.beginUndoGrouping()
            modelContext.delete(task)
            if let index = items.firstIndex(of: task) {
                items.remove(at: index)
            }
            for c in task.comments ?? [] {
                modelContext.delete(c)
            }
            modelContext.endUndoGrouping()
            updateUndoRedoStatus()
        }
    }
    
    func move(task: TaskItem, to: TaskItemState) {
        if task.state == to {
            return // nothing to be done
        }
        switch task.state {
            case .closed: closedTasks.removeObject(task)
            case .dead: deadTasks.removeObject(task)
            case .pendingResponse: pendingTasks.removeObject(task)
            case .open: openTasks.removeObject(task)
            case .priority :priorityTasks.removeObject(task)
        }
       
        switch to {
            case .open:
                task.reOpenTask()
                openTasks.append(task)
                openTasks.sort()
            case .closed:
                task.closeTask()
                closedTasks.append(task)
                closedTasks.sort()
            case .dead:
                task.graveyard()
                deadTasks.append(task)
                deadTasks.sort()
            case .priority:
                task.makePriority()
                priorityTasks.append(task)
                priorityTasks.sort()
            case .pendingResponse:
                task.pending()
                pendingTasks.append(task)
                pendingTasks.sort()
        }
        updateUndoRedoStatus()
    }
}

extension TaskManagerViewModel {
    func list(which: TaskItemState) -> [TaskItem] {
        switch which {
            case .open: return openTasks
            case .closed: return closedTasks
            case .dead: return deadTasks
            case .priority: return priorityTasks
            case .pendingResponse: return pendingTasks
        }
    }
    
    var currentList: [TaskItem] {
        return list(which: whichList)
    }
}

//
//extension TaskManagerViewModel {
//    internal var undoManager: UndoManager? {
//        return modelContext.undoManager
//    }
//}

// for testing purposes
extension TaskManagerViewModel {
    
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
