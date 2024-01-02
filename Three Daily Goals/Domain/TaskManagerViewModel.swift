//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import Foundation
import SwiftData
import SwiftUI

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
    case openItems
    case closedItems
    case deadItems
    case priorities
}


extension ListChooser {
    var sections: [TaskSection] {
        switch self {
            case .openItems : return [secOpen]
            case .closedItems: return [secClosed]
            case .deadItems: return [secGraveyard]
            case .priorities: return [secToday]
        }
    }
}


@Observable
final class TaskManagerViewModel {
    private let modelContext: ModelContext
    private(set) var items = [TaskItem]()
    
    func select(which: ListChooser, item: TaskItem?) {
        whichList = which
        selectedItem = item
    }
    
    ///used in Content view of NavigationSplitView
    var whichList = ListChooser.openItems
    
    /// used in Detail View of NavigationSplitView
    var selectedItem: TaskItem? = nil
    
    
    var showItem: Bool = false
    var canUndo = false
    var canRedo = false
    
    var showReviewDialog: Bool = false
    
    var openItems: [TaskItem] {
        return items.filter({$0.state == .open}).sorted()
    }
    
    var closedItems: [TaskItem]{
        return items.filter({$0.state == .closed}).sorted()
    }
    
    var deadItems: [TaskItem]{
        return items.filter({$0.state == .graveyard}).sorted()
    }
    
    var today: DailyTasks? = nil
    
    func updateModels() {
        
        updateUndoRedoStatus()
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
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
    
    func clear() {
        try? modelContext.delete(model: TaskItem.self)
        try? modelContext.save()
        fetchData()
    }
    
    func fetchData() {
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.changed, order: .reverse)])
            items = try modelContext.fetch(descriptor)
            updateModels()
        } catch {
            print("Fetch failed")
        }
    }
    
    func addItem() {
        let newItem = TaskItem()
        modelContext.insert(newItem)
        select(which: .openItems, item: newItem)
#if os(iOS)
        showItem = true
#endif
        updateUndoRedoStatus()
    }
    
    func undo() {
        modelContext.undoManager?.undo()
        updateUndoRedoStatus()
    }
    
    func redo() {
        modelContext.undoManager?.redo()
        updateUndoRedoStatus()
    }
    
    func updateUndoRedoStatus() {
        canUndo =  modelContext.undoManager?.canUndo ?? false
        canRedo =  modelContext.undoManager?.canRedo ?? false
    }
    
    func loadToday() {
        today = loadPriorities(modelContext: modelContext)
        updateModels()
    }
    
    func priority (which: Int) -> TaskItem? {
        return today?.priorities?[which]
    }
}

extension TaskManagerViewModel {
    func list(which: ListChooser) -> [TaskItem] {
        switch which {
            case .openItems: return openItems
            case .closedItems: return closedItems
            case .deadItems: return deadItems
            case .priorities: return today?.priorities ?? []
        }
    }
    
    var currentList: [TaskItem] {
        return list(which: whichList)
    }
}
