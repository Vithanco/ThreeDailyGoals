//
//  ModelContainer.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation
import SwiftData
import CoreData


typealias TaskSelector = ([TaskSection],[TaskItem],TaskItem?) -> Void
typealias OnSelectItem = (TaskItem) -> Void

fileprivate var container: ModelContainer? = nil

extension ModelContainer {
    var isInMemory: Bool {
        return configurations.contains(where: { $0.isStoredInMemoryOnly })
    }
}



protocol Storage {
    func insert<T>(_ model: T) where T : PersistentModel
    func save() throws
    func beginUndoGrouping()
    func endUndoGrouping()
    func processPendingChanges()
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel
    func delete<T>(_ model: T) where T : PersistentModel
    func undo()
    func redo()
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    var undoManager: UndoManager? {get}
}

extension ModelContext: Storage {
    func undo() {
        undoManager?.undo()
    }
    
    func redo() {
        undoManager?.redo()
    }
    
    var canUndo: Bool {
        undoManager?.canUndo ?? false
    }
    
    var canRedo: Bool {
        undoManager?.canRedo ?? false
    }
    
    func beginUndoGrouping() {
        undoManager?.beginUndoGrouping()
        processPendingChanges()
    }
    
    func endUndoGrouping() {
        undoManager?.endUndoGrouping()
        processPendingChanges()
    }
}

extension Array where Element == TaskItem {
    @discardableResult mutating func add(title: String, changedDate: Date, state: TaskItemState = .open) -> TaskItem {
        let new = TaskItem(title: title, changedDate: changedDate, state: state)
        self.append(new)
        return new
    }
}


class TestStorage : Storage {
    var undoManager: UndoManager? = nil
    
    func insert<T>(_ model: T) where T : PersistentModel {
        
    }
    
    func save() throws {
        
    }
    
    func beginUndoGrouping() {
        
    }
    
    func endUndoGrouping() {
        
    }
    
    func processPendingChanges() {
        
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        if T.self == TaskItem.self {
            var result : [TaskItem] = []
            let theGoal = result.add(title: "Read 'The Goal' by Goldratt", changedDate: Date.now.addingTimeInterval(-1 * Seconds.fiveMin))
            theGoal.details = "It is the book that introduced the fundamentals for 'Theory of Constraints'"
            theGoal.url = "https://www.goodreads.com/book/show/113934.The_Goal"
            result.add(title: "Try out Concept Maps", changedDate: getDate(daysPrior: 3), state: .priority)
            result.add(title: "Read about Systems Thinking", changedDate: getDate(daysPrior: 5))
            result.add(title: "Transfer tasks from old task manager into this one", changedDate: getDate(daysPrior: 11), state: .open)
            let lastMonth2 = result.add(title: "Read about Structured Visual Thinking", changedDate: getDate(daysPrior: 22),state: .pendingResponse)
            lastMonth2.url = "https://vithanco.com"
            result.add(title: "Contact Vithanco Author regarding new map style", changedDate: getDate(daysPrior: 3),state: .pendingResponse)
            result.add(title: "Read this", changedDate: getDate(daysPrior: 31), state: .dead)
            result.add(title: "Read this about Agile vs Waterfall", changedDate: getDate(daysPrior: 101), state: .dead)
            return result as! [T]
        }
        return []
    }
    
    func delete<T>(_ model: T) where T : PersistentModel {
        
    }
    
    func undo() {
        
    }
    
    func redo() {
        
    }
    
    var canUndo: Bool = false
    
    var canRedo: Bool = false
    
    
}

func sharedModelContainer(inMemory: Bool) -> ModelContainer {
    if let result = container, result.isInMemory == inMemory {
        return result
    }
    
    let schema = Schema(versionedSchema: SchemaLatest.self)
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
    
    do {
        let result = try ModelContainer(
            for: schema,
            migrationPlan: TDGMigrationPlan.self,
            configurations: [modelConfiguration])
        DispatchQueue.main.async {
            result.mainContext.undoManager = UndoManager()
        }
        container = result
        return result
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}

