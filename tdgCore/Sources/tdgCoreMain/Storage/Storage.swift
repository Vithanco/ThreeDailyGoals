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

/// Custom error types for database operations
public enum DatabaseError: LocalizedError {
    case migrationFailed(underlyingError: Error)
    case containerCreationFailed(underlyingError: Error)
    case unsupportedSchemaVersion
    case cloudKitSyncFailed(underlyingError: Error)
    case dataCorruption

    public var errorDescription: String? {
        switch self {
        case .migrationFailed(let error):
            return "Database migration failed: \(error.localizedDescription)"
        case .containerCreationFailed(let error):
            return "Failed to create database container: \(error.localizedDescription)"
        case .unsupportedSchemaVersion:
            return "Database schema version is not supported by this app version"
        case .cloudKitSyncFailed(let error):
            return "CloudKit synchronization failed: \(error.localizedDescription)"
        case .dataCorruption:
            return "Database data appears to be corrupted"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .migrationFailed, .containerCreationFailed, .unsupportedSchemaVersion:
            return "Please update the app to the latest version from the App Store to resolve this issue."
        case .cloudKitSyncFailed:
            return "Check your internet connection and try again. If the problem persists, please update the app."
        case .dataCorruption:
            return "Please update the app to the latest version. If the problem continues, contact support."
        }
    }

    public var isUpgradeRequired: Bool {
        switch self {
        case .migrationFailed, .containerCreationFailed, .unsupportedSchemaVersion, .dataCorruption:
            return true
        case .cloudKitSyncFailed:
            return false
        }
    }

    public var userFriendlyTitle: String {
        switch self {
        case .migrationFailed, .containerCreationFailed, .unsupportedSchemaVersion, .dataCorruption:
            return "App Update Required"
        case .cloudKitSyncFailed:
            return "Sync Error"
        }
    }

    public var userFriendlyMessage: String {
        switch self {
        case .migrationFailed, .containerCreationFailed, .unsupportedSchemaVersion, .dataCorruption:
            return
                "Your app needs to be updated to work with the latest data format. Please update to the latest version from the App Store."
        case .cloudKitSyncFailed:
            return "There was a problem syncing your data. Please check your internet connection and try again."
        }
    }
}

public typealias TaskSelector = ([TaskSection], [TaskItem], TaskItem?) -> Void
public typealias OnSelectItem = (TaskItem) -> Void

@MainActor
private var container: ModelContainer? = nil

/// Global storage for migration issues that need to be reported to users
@MainActor
private var pendingMigrationIssues: [(message: String, details: String?)] = []

/// Report a migration issue that will be shown to the user after app setup
@MainActor
public func reportMigrationIssue(_ message: String, details: String? = nil) {
    pendingMigrationIssues.append((message: message, details: details))
}

/// Get and clear all pending migration issues
@MainActor
public func getPendingMigrationIssues() -> [(message: String, details: String?)] {
    let issues = pendingMigrationIssues
    pendingMigrationIssues.removeAll()
    return issues
}

extension ModelContainer {
    public var isInMemory: Bool {
        return configurations.contains(where: { $0.isStoredInMemoryOnly })
    }
}

public protocol Storage {
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

extension ModelContext: @preconcurrency Storage {
    @MainActor public func undo() {
        undoManager?.undo()
    }

    @MainActor public func redo() {
        undoManager?.redo()
    }

    @MainActor public var canUndo: Bool {
        undoManager?.canUndo ?? false
    }

    @MainActor public var canRedo: Bool {
        undoManager?.canRedo ?? false
    }

    @MainActor public func beginUndoGrouping() {
        undoManager?.beginUndoGrouping()
        processPendingChanges()
    }

    @MainActor public func endUndoGrouping() {
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
        new.tags = tags.map { $0.lowercased() }
        self.append(new)
        return new
    }
}

/// A Sendable type for loading test data
public typealias TestDataLoader = @Sendable (TimeProvider) -> [TaskItem]

public class TestStorage: Storage {
    public var hasChanges: Bool {
        return false
    }

    public var undoManager: UndoManager? = nil
    public var items: [TaskItem]

    public init(timeProvider: TimeProvider) {
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

    public init(loader: @escaping TestDataLoader, timeProvider: TimeProvider) {
        items = loader(timeProvider)
    }

    public func insert<T>(_ model: T) where T: PersistentModel {

    }

    public func save() throws {

    }

    public func beginUndoGrouping() {

    }

    public func endUndoGrouping() {

    }

    public func processPendingChanges() {

    }

    public func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T: PersistentModel {
        if T.self == TaskItem.self {
            return items as! [T]
        }
        return []
    }

    public func delete<T>(_ model: T) where T: PersistentModel {

    }

    public func undo() {

    }

    public func redo() {

    }

    public var canUndo: Bool = false

    public var canRedo: Bool = false

}

/// A default empty loader for testing
public let emptyTestDataLoader: TestDataLoader = { _ in return [] }

@MainActor
public func sharedModelContainer(inMemory: Bool, withCloud: Bool) -> Result<ModelContainer, DatabaseError> {
    if let result = container, result.isInMemory == inMemory {
        return .success(result)
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
        return .success(result)
    } catch {
        // Check if this is a migration-related error
        let errorString = error.localizedDescription.lowercased()
        if errorString.contains("migration") || errorString.contains("schema") || errorString.contains("version") {
            return .failure(.migrationFailed(underlyingError: error))
        } else if errorString.contains("cloudkit") || errorString.contains("sync") {
            return .failure(.cloudKitSyncFailed(underlyingError: error))
        } else {
            return .failure(.containerCreationFailed(underlyingError: error))
        }
    }
}

// Helper function to create a task for testing
public func createTestTask(
    title: String,
    changedDate: Date,
    state: TaskItemState = .open,
    details: String = "",
    tags: [String] = []
) -> TaskItem {
    // Create a new task item
    let task = TaskItem(title: title, changedDate: changedDate, state: state)
    task.details = details
    task.tags = tags.map { $0.lowercased() }
    return task
}
