//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import Foundation
import SwiftData


class ListViewModel :ObservableObject {
    @Published var sections: [TaskSection]
    @Published var list: [TaskItem]
    
    init(sections: [TaskSection], list: [TaskItem]) {
        self.sections = sections
        self.list = list
    }
}


@Observable
final class TaskManagerViewModel {
    private let modelContext: ModelContext
    private(set) var items = [TaskItem]()
    
    func select(sections: [TaskSection], list: [TaskItem], item: TaskItem?) {
        listModel.sections = sections
        listModel.list = list
        selectedItem = item
    }
    
    ///used in Content view of NavigationSplitView
    var listModel = ListViewModel(sections: [], list: [])
    
    /// all open items
    var openModel : ListViewModel = ListViewModel(sections: [secOpen], list: [])
    
    /// all closed items
    var closedModel = ListViewModel(sections: [secClosed], list: [])
    
    /// all dead items
    var deadModel = ListViewModel(sections: [secGraveyard], list: [])
    
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
        openModel.list = openItems
        closedModel.list = closedItems
        deadModel.list = deadItems
        updateUndoRedoStatus()
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }
    
    func addSamples() {
        let lastWeek1 = TaskItem(title: "3 days ago", changedDate: getDate(daysPrior: 3))
        let lastWeek2 = TaskItem(title: "5 days ago", changedDate: getDate(daysPrior: 5))
        let lastMonth1 = TaskItem(title: "11 days ago", changedDate: getDate(daysPrior: 11))
        let lastMonth2 = TaskItem(title: "22 days ago", changedDate: getDate(daysPrior: 22))
        let older1 = TaskItem(title: "31 days ago", changedDate: getDate(daysPrior: 31))
        let older2 = TaskItem(title: "101 days ago", changedDate: getDate(daysPrior: 101))
        modelContext.insert(lastWeek1)
        modelContext.insert(lastWeek2)
        modelContext.insert(lastMonth1)
        modelContext.insert(lastMonth2)
        modelContext.insert(older1)
        modelContext.insert(older2)
        
        try? modelContext.save()
        fetchData()
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
        openModel.list.append(newItem)
#if os(macOS)
        select(sections: [secOpen], list: openItems, item: newItem)
#endif
#if os(iOS)
        selectedItem = newItem
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
}
