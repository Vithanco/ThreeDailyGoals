//
//  ModelContainer.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation
import SwiftData
import CoreData
import CloudKit


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
    @discardableResult mutating func add(title: String, changedDate: Date, state: TaskItemState = .open, tags: [String] = [], dueDate: Date? = nil) -> TaskItem {
        let new = TaskItem(title: title, changedDate: changedDate, state: state)
        new.dueDate = dueDate
        new.tags = tags
        self.append(new)
        return new
    }
}


class TestStorage : Storage {
    typealias Loader = (() -> [TaskItem])
    
    var loader: Loader
    var undoManager: UndoManager? = nil
    
    init(loader: @escaping Loader) {
        self.loader = loader
    }
    
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
            return loader() as! [T]
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


extension CKContainer {
    public var isProductionEnvironment:Bool {
        let containerID = self.value(forKey: "containerID") as! NSObject // CKContainerID
        return containerID.value(forKey: "environment")! as! CLongLong == 1
    }
    
    public static var isProductionEnvironment: Bool {
        let container = CKContainer.default()
        if let containerID = container.value(forKey: "containerID") as? NSObject {
            debugPrint(containerID)
            return containerID.description.contains("Production")
        }
        return false
    }
}


