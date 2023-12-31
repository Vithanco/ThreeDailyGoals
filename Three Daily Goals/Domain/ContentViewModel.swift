//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import Foundation
import SwiftData

@Observable
final class TaskManagerViewModel {
    private let modelContext: ModelContext
    private(set) var items = [TaskItem]()
    
    var openModel : ListViewModel = ListViewModel(sections: [secOpen], list: [])
    var closedModel = ListViewModel(sections: [secClosed], list: [])
    var deadModel = ListViewModel(sections: [secGraveyard], list: [])
    
    var selectedItem: TaskItem? = nil
    private var showItem: Bool = false
    private var canUndo = false
    private var canRedo = false
    
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
}
