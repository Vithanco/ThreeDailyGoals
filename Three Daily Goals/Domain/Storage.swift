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
            let lastWeek1 = TaskItem(title: "3 days ago", changedDate: getDate(daysPrior: 3))
            let lastWeek2 = TaskItem(title: "5 days ago", changedDate: getDate(daysPrior: 5))
            let lastMonth1 = TaskItem(title: "11 days ago", changedDate: getDate(daysPrior: 11), state: .priority)
            let lastMonth2 = TaskItem(title: "22 days ago", changedDate: getDate(daysPrior: 22),state: .pendingResponse)
            let older1 = TaskItem(title: "31 days ago", changedDate: getDate(daysPrior: 31))
            let older2 = TaskItem(title: "101 days ago", changedDate: getDate(daysPrior: 101))
            return [lastWeek1, lastMonth1,lastWeek2,older1,older2,lastMonth2] as! [T]
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

