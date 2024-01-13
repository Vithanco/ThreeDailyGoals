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

enum ListChooser{
    case openTasks
    case closedTasks
    case deadTasks
    case priorityTasks
    case pendingTasks
}


extension ListChooser {
    var sections: [TaskSection] {
        switch self {
            case .openTasks : return [secOpen]
            case .closedTasks: return [secClosed]
            case .deadTasks: return [secGraveyard]
            case .priorityTasks: return [secToday]
            case .pendingTasks: return [secPending]
        }
    }
}



@Observable
final class TaskManagerViewModel {
    private let modelContext: Storage
    private(set) var items = [TaskItem]()
    
    func select(which: ListChooser, item: TaskItem?) {
        withAnimation {
            whichList = which
            selectedItem = item
        }
    }
    
    ///used in Content view of NavigationSplitView
    var whichList = ListChooser.openTasks
    
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
    
    var today: DailyTasks? = nil
    
    
    init(modelContext: Storage) {
        self.modelContext = modelContext
        
//        NotificationCenter.default.notifications(named: Notification.Name.NSManagedObjectContextObjectsDidChange)
        NotificationCenter.default.addObserver(self,
                                   selector: #selector(notification(_ :)),
                                   name: .NSPersistentStoreRemoteChange,
                                   object: nil)
        fetchData()
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
        today?.priorities?.append(lastWeek1)
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
            for item in items {
                switch item.state {
                    case .open:
                        if item.priority == nil {
                            // don't add priorities to open Items
                            openTasks.append(item)
                        }
                    case .closed : closedTasks.append(item)
                    case .pendingResponse : pendingTasks.append(item)
                    case .graveyard: deadTasks.append(item)
                }
            }
            openTasks = openTasks.sorted()
            closedTasks = closedTasks.sorted()
            pendingTasks = pendingTasks.sorted()
            deadTasks = deadTasks.sorted()
            updateUndoRedoStatus()
        } catch {
            print("Fetch failed")
        }
    }
    
    @discardableResult func addItem() -> TaskItem {
        modelContext.beginUndoGrouping()
        let newItem = TaskItem()
        modelContext.insert(newItem)
        items.append(newItem)
        modelContext.endUndoGrouping()
        modelContext.processPendingChanges()
        #if os(macOS)
        select(which: .openTasks, item: newItem)
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
            modelContext.undo()
            modelContext.processPendingChanges()
            fetchData()
        }
    }
    
    func redo() {
        withAnimation {
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
        today = loadPriorities(modelContext: modelContext)
    }
    
    func priority (which: Int) -> TaskItem? {
        return today?.priorities?[which]
    }
    
    func findTask(withID: String) -> TaskItem? {
        let result = items.first(where: {$0.id == withID})
        logger.debug("found Task '\(result != nil)' for ID: \(withID)")
        return result
    }
    
    func delete(task: TaskItem) {
        withAnimation {
            modelContext.beginUndoGrouping()
            task.deleteTask()
            if let index = items.firstIndex(of: task) {
                items.remove(at: index)
            }
            modelContext.endUndoGrouping()
            updateUndoRedoStatus()
        }
    }
    
    func removeFromList(task: TaskItem) {
        switch task.state {
            case .closed: closedTasks.removeObject(task)
            case .graveyard: deadTasks.removeObject(task)
            case .pendingResponse: pendingTasks.removeObject(task)
            case .open:
                openTasks.removeObject(task)
                task.priority = nil
        }
    }
    
    func move(task: TaskItem, to: ListChooser) {
        if task.belongsTo == to {
            return // nothing to be done
        }
       
        switch to {
            case .openTasks: 
                task.reOpenTask()
                task.priority = nil
                openTasks.append(task)
            case .closedTasks:
                task.closeTask()
                task.priority = nil
                closedTasks.append(task)
            case .deadTasks:
                task.graveyard()
                task.priority = nil
                deadTasks.append(task)
            case .priorityTasks:
                if let today = today {
                    task.makePriority(position: 0, day: today)
                }
            case .pendingTasks:
                task.pending()
                pendingTasks.append(task)
        }
    }
}

extension TaskManagerViewModel {
    func list(which: ListChooser) -> [TaskItem] {
        switch which {
            case .openTasks: return openTasks - (today?.priorities ?? [])
            case .closedTasks: return closedTasks
            case .deadTasks: return deadTasks
            case .priorityTasks: return today?.priorities ?? []
            case .pendingTasks: return pendingTasks
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
    }
    
    func endUndoGrouping() {
        modelContext.endUndoGrouping()
    }
}
