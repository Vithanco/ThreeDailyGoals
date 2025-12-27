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
        new.updateTags(tags.map { $0.lowercased() }, createComments: false)
        self.append(new)
        return new
    }
}

/// A Sendable type for loading test data
public typealias TestDataLoader = @Sendable (TimeProvider) -> [TaskItem]

/// Creates default test data for testing and development
public func createDefaultTestData(timeProvider: TimeProvider) -> [TaskItem] {
    var result: [TaskItem] = []
    let theGoal = result.add(
        title: "Read 'The Goal' by Goldratt",
        changedDate: timeProvider.now.addingTimeInterval(-1 * Seconds.fiveMin))
    theGoal.created = theGoal.changed  // Match created to changed for test data
    theGoal.details = "It is the book that introduced the fundamentals for 'Theory of Constraints'"
    theGoal.url = "https://www.goodreads.com/book/show/113934.The_Goal"
    theGoal.dueDate = timeProvider.getDate(inDays: 2)
    result.add(
        title: "Try out Concept Maps", changedDate: timeProvider.getDate(daysPrior: 3), state: .priority,
        tags: ["CMaps"]
    ).created = timeProvider.getDate(daysPrior: 3)
    result.add(
        title: "Read about Systems Thinking", changedDate: timeProvider.getDate(daysPrior: 5), tags: ["toRead", "work"]
    ).created = timeProvider.getDate(daysPrior: 5)
    result.add(
        title: "Transfer tasks from old task manager into this one",
        changedDate: timeProvider.getDate(daysPrior: 11), state: .open
    ).created = timeProvider.getDate(daysPrior: 11)
    let lastMonth2 = result.add(
        title: "Read about Structured Visual Thinking",
        changedDate: timeProvider.getDate(daysPrior: 22),
        state: .open,
        tags: ["toRead"]
    )
    lastMonth2.created = lastMonth2.changed  // Match created to changed for test data
    lastMonth2.url = "https://vithanco.com"
    result.add(
        title: "Contact Vithanco Author regarding new map style", changedDate: timeProvider.getDate(daysPrior: 3),
        state: .pendingResponse
    ).created = timeProvider.getDate(daysPrior: 3)
    result.add(title: "Read this", changedDate: timeProvider.getDate(daysPrior: 31), state: .dead).created =
        timeProvider.getDate(daysPrior: 31)
    result.add(
        title: "Read this about Agile vs Waterfall", changedDate: timeProvider.getDate(daysPrior: 101),
        state: .dead
    ).created = timeProvider.getDate(daysPrior: 101)
    result.add(
        title: "Request Parking Permission", changedDate: timeProvider.getDate(inDays: 3), state: .pendingResponse
    ).created = timeProvider.getDate(inDays: 3)
    result.add(
        title: "Tax Declaration", changedDate: timeProvider.getDate(inDays: 30), state: .open,
        tags: ["private"], dueDate: timeProvider.getDate(inDays: 2)
    ).created = timeProvider.getDate(inDays: 30)

    // Exploring Three Daily Goals App features
    let widgetTask = result.add(
        title: "Add widget to home screen",
        changedDate: timeProvider.getDate(daysPrior: 1),
        state: .priority,
        tags: ["widget", "setup"])
    widgetTask.created = widgetTask.changed  // Match created to changed for test data
    widgetTask.details =
        "Explore the widget feature - long press on home screen, search for Three Daily Goals, and add the widget to see your priorities at a glance"

    let shareTask = result.add(
        title: "Try sharing a webpage to Three Daily Goals",
        changedDate: timeProvider.getDate(daysPrior: 2),
        state: .open,
        tags: ["share", "feature"])
    shareTask.created = shareTask.changed  // Match created to changed for test data
    shareTask.details =
        "Test the share extension: open Safari, tap the share button, and select Three Daily Goals to create a task from any webpage"
    shareTask.url = "https://www.apple.com"

    let compassTask = result.add(
        title: "Complete my first Compass Check",
        changedDate: timeProvider.now,
        state: .priority,
        tags: ["compass", "review"])
    compassTask.created = compassTask.changed  // Match created to changed for test data
    compassTask.details =
        "The Compass Check helps you reflect on what you've done and plan ahead. Access it from the menu to review your progress and set new priorities"

    result.add(
        title: "Organize tasks with tags",
        changedDate: timeProvider.getDate(daysPrior: 1),
        state: .open,
        tags: ["productivity", "organization"]
    ).created = timeProvider.getDate(daysPrior: 1)

    let undoTask = result.add(
        title: "Explore undo/redo functionality",
        changedDate: timeProvider.getDate(daysPrior: 4),
        state: .closed,
        tags: ["feature"])
    undoTask.created = undoTask.changed  // Match created to changed for test data
    undoTask.details = "Try making changes and using Cmd+Z (macOS) to undo them. All changes can be undone and redone!"

    result.add(
        title: "Set up daily Compass Check reminder",
        changedDate: timeProvider.getDate(daysPrior: 2),
        state: .pendingResponse,
        tags: ["compass", "notifications"]
    ).created = timeProvider.getDate(daysPrior: 2)

    let exportTask = result.add(
        title: "Export tasks to JSON for backup",
        changedDate: timeProvider.getDate(daysPrior: 6),
        state: .open,
        tags: ["backup", "data"])
    exportTask.created = exportTask.changed  // Match created to changed for test data
    exportTask.details =
        "Use File → Export to save all your tasks as JSON. Great for backups or migrating to another device"

    result.add(
        title: "Test CloudKit sync between devices",
        changedDate: timeProvider.getDate(daysPrior: 3),
        state: .open,
        tags: ["sync", "icloud"]
    ).created = timeProvider.getDate(daysPrior: 3)

    let attachmentTask = result.add(
        title: "Add attachments to important tasks",
        changedDate: timeProvider.getDate(daysPrior: 5),
        state: .open,
        tags: ["attachments", "feature"])
    attachmentTask.created = attachmentTask.changed  // Match created to changed for test data
    attachmentTask.details =
        "You can add images and files to tasks. Try it with screenshots, PDFs, or photos relevant to your work"

    result.add(
        title: "Customize Compass Check steps in preferences",
        changedDate: timeProvider.getDate(daysPrior: 7),
        state: .closed,
        tags: ["compass", "preferences", "customization"]
    ).created = timeProvider.getDate(daysPrior: 7)

    return result
}

/// A default empty loader for testing
public let emptyTestDataLoader: TestDataLoader = { _ in return [] }

@MainActor
public func sharedModelContainer(inMemory: Bool, withCloud: Bool) -> Result<ModelContainer, DatabaseError> {
    // Don't cache in-memory containers (used for testing) - each test should get a fresh container
    if !inMemory, let result = container, result.isInMemory == inMemory {
        return .success(result)
    }

    let schema = Schema(versionedSchema: SchemaLatest.self)
    let useCloudDB =
        (inMemory || !withCloud)
        ? ModelConfiguration.CloudKitDatabase.none : ModelConfiguration.CloudKitDatabase.automatic

    // Configure storage location
    let modelConfiguration: ModelConfiguration
    if inMemory {
        // For in-memory storage (testing), don't specify a URL
        modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: useCloudDB)
    } else {
        // For persistent storage, use App Group container so widgets and share extensions can access the data
        let appGroupIdentifier = "group.com.vithanco.three-daily-goals"
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        {
            let storeURL = appGroupURL.appendingPathComponent("default.store")
            modelConfiguration = ModelConfiguration(url: storeURL, cloudKitDatabase: useCloudDB)
        } else {
            // Fallback to default location if App Group is not available (shouldn't happen in production)
            modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: useCloudDB)
        }
    }

    do {
        let result = try ModelContainer(
            for: schema,
            migrationPlan: TDGMigrationPlan.self,
            configurations: [modelConfiguration]
        )
        result.mainContext.undoManager = UndoManager()
        // Only cache persistent containers, not in-memory ones
        if !inMemory {
            container = result
        }
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
