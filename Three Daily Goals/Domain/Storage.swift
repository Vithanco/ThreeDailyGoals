//
//  ModelContainer.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import CloudKit
import CoreData
import Foundation
import SwiftData

typealias TaskSelector = ([TaskSection], [TaskItem], TaskItem?) -> Void
typealias OnSelectItem = (TaskItem) -> Void

@MainActor
private var container: ModelContainer? = nil

extension ModelContainer {
    var isInMemory: Bool {
        return configurations.contains(where: { $0.isStoredInMemoryOnly })
    }
}

protocol Storage {
    func insert<T>(_ model: T) where T: PersistentModel
    func save() throws
    func beginUndoGrouping()
    func endUndoGrouping()
    func processPendingChanges()
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T: PersistentModel
    func delete<T>(_ model: T) where T: PersistentModel
    func undo()
    func redo()
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    var undoManager: UndoManager? { get }
    var hasChanges: Bool { get }
}

extension ModelContext: @MainActor Storage {
    @MainActor func undo() {
        undoManager?.undo()
    }

    @MainActor func redo() {
        undoManager?.redo()
    }

    @MainActor var canUndo: Bool {
        undoManager?.canUndo ?? false
    }

    @MainActor var canRedo: Bool {
        undoManager?.canRedo ?? false
    }

    @MainActor func beginUndoGrouping() {
        undoManager?.beginUndoGrouping()
        processPendingChanges()
    }

    @MainActor func endUndoGrouping() {
        undoManager?.endUndoGrouping()
        processPendingChanges()
    }
}

extension Array where Element == TaskItem {
    @discardableResult mutating func add(
        title: String,
        changedDate: Date,
        state: TaskItemState = .open,
        tags: [String] = [],
        dueDate: Date? = nil
    ) -> TaskItem {
        let new = TaskItem(title: title, changedDate: changedDate, state: state)
        new.dueDate = dueDate
        new.tags = tags
        self.append(new)
        return new
    }
}

class TestStorage: Storage {
    var hasChanges: Bool {
        return false
    }

    typealias Loader = ((TimeProvider) -> [TaskItem])

    var undoManager: UndoManager? = nil
    var items: [TaskItem]
    
    init(timeProvider: TimeProvider) {
        var result: [TaskItem] = []
        let theGoal = result.add(
            title: "Read 'The Goal' by Goldratt",
            changedDate: timeProvider.now.addingTimeInterval(-1 * Seconds.fiveMin))
        theGoal.details = "It is the book that introduced the fundamentals for 'Theory of Constraints'"
        theGoal.url = "https://www.goodreads.com/book/show/113934.The_Goal"
        theGoal.dueDate = timeProvider.getDate(inDays: 2)
        result.add(
            title: "Try out Concept Maps", changedDate: timeProvider.getDate(daysPrior: 3), state: .priority,
            tags: ["CMaps"])
        result.add(
            title: "Read about Systems Thinking", changedDate: timeProvider.getDate(daysPrior: 5), tags: ["toRead"])
        result.add(
            title: "Transfer tasks from old task manager into this one",
            changedDate: timeProvider.getDate(daysPrior: 11), state: .open)
        let lastMonth2 = result.add(
            title: "Read about Structured Visual Thinking",
            changedDate: timeProvider.getDate(daysPrior: 22),
            state: .open,
            tags: ["toRead"]
        )
        lastMonth2.url = "https://vithanco.com"
        result.add(
            title: "Contact Vithanco Author regarding new map style", changedDate: timeProvider.getDate(daysPrior: 3),
            state: .pendingResponse)
        result.add(title: "Read this", changedDate: timeProvider.getDate(daysPrior: 31), state: .dead)
        result.add(
            title: "Read this about Agile vs Waterfall", changedDate: timeProvider.getDate(daysPrior: 101),
            state: .dead)
        result.add(
            title: "Request Parking Permission", changedDate: timeProvider.getDate(inDays: 3), state: .pendingResponse)
        result.add(
            title: "Tax Declaration", changedDate: timeProvider.getDate(inDays: 30), state: .open,
            dueDate: timeProvider.getDate(inDays: 2))
        for i in 32..<200 {
            result.add(title: "Dead Task \(i)", changedDate: timeProvider.getDate(daysPrior: i), state: .dead)
        }
        items = result
    }

    init(loader: @escaping Loader, timeProvider: TimeProvider) {
        items = loader(timeProvider)
    }

    func insert<T>(_ model: T) where T: PersistentModel {

    }

    func save() throws {

    }

    func beginUndoGrouping() {

    }

    func endUndoGrouping() {

    }

    func processPendingChanges() {

    }

    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T: PersistentModel {
        if T.self == TaskItem.self {
            return items as! [T]
        }
        return []
    }

    func delete<T>(_ model: T) where T: PersistentModel {

    }

    func undo() {

    }

    func redo() {

    }

    var canUndo: Bool = false

    var canRedo: Bool = false

}

@MainActor
public func sharedModelContainer(inMemory: Bool, withCloud: Bool) -> ModelContainer {
    if let result = container, result.isInMemory == inMemory {
        return result
    }

    let schema = Schema(versionedSchema: SchemaLatest.self)
    let useCloudDB =
        (inMemory || !withCloud)
        ? ModelConfiguration.CloudKitDatabase.none : ModelConfiguration.CloudKitDatabase.automatic

    let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: useCloudDB)

    do {
        let result = try ModelContainer(
            for: schema,
            migrationPlan: TDGMigrationPlan.self,
            configurations: [modelConfiguration]
        )
        result.mainContext.undoManager = UndoManager()
        container = result
        return result
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}


