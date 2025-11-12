import Foundation
import SwiftData
import SwiftUI
import WidgetKit
import tdgCoreMain

/// Struct containing all app components and managers
public struct AppComponents {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let preferences: CloudPreferences
    let uiState: UIStateManager
    let dataManager: DataManager
    let compassCheckManager: CompassCheckManager
    let pushNotificationManager: PushNotificationManager
    let timeProvider: TimeProvider
    let timeProviderWrapper: TimeProviderWrapper
    let isTesting: Bool
}

/// Set up the app with all necessary components
/// - Parameter isTesting: If true, creates a test setup with dummy data
/// - Parameter timeProvider: TimeProvider to use. Defaults to RealTimeProvider for production or MockTimeProvider for testing
/// - Parameter loader: Optional test data loader
/// - Parameter preferences: Optional custom preferences for testing
/// - Parameter customSteps: Optional custom CompassCheck steps. If nil, uses DEFAULT_STEPS
/// - Returns: AppComponents struct containing all managers and components
@MainActor
public func setupApp(
    isTesting: Bool, timeProvider: TimeProvider? = nil, loaderForTests: TestDataLoader? = nil,
    preferences: CloudPreferences? = nil, compassCheckSteps: [any CompassCheckStep] = CompassCheckManager.DEFAULT_STEPS
) -> AppComponents {

    // MARK: - Step 1: Create TimeProvider (needed by everything)
    let finalTimeProvider = timeProvider ?? (isTesting ? MockTimeProvider(fixedNow: Date.now) : RealTimeProvider())

    // MARK: - Step 2: Create Storage Layer
    let container: ModelContainer
    let modelContext: ModelContext
    let finalModelContext: ModelContext
    var databaseError: DatabaseError?

    // Create a shared undo manager for all contexts
    let sharedUndoManager = UndoManager()

    if isTesting {
        // Test setup - create in-memory container
        switch sharedModelContainer(inMemory: true, withCloud: false) {
        case .success(let testContainer):
            container = testContainer
            modelContext = ModelContext(container)
            modelContext.undoManager = sharedUndoManager

            // Populate with test data once on startup
            let testData = loaderForTests?(finalTimeProvider) ?? createDefaultTestData(timeProvider: finalTimeProvider)
            for item in testData {
                modelContext.insert(item)
            }
            try? modelContext.save()

            print("✅ Populated ModelContext with \(testData.count) test items")
            finalModelContext = modelContext

        case .failure(let error):
            // Fallback with minimal container
            container = try! ModelContainer(
                for: TaskItem.self, Attachment.self, Comment.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            modelContext = ModelContext(container)
            modelContext.undoManager = sharedUndoManager

            // Still populate with test data
            let testData = createDefaultTestData(timeProvider: finalTimeProvider)
            for item in testData {
                modelContext.insert(item)
            }
            try? modelContext.save()

            finalModelContext = modelContext
            print("⚠️ Database container creation failed in test mode: \(error)")
        }
    } else {
        // Production setup
        switch sharedModelContainer(inMemory: false, withCloud: true) {
        case .success(let prodContainer):
            container = prodContainer
            modelContext = ModelContext(container)
            modelContext.undoManager = sharedUndoManager
            finalModelContext = modelContext
        case .failure(let error):
            // For production, we need to handle this gracefully
            // Create a minimal container for basic functionality
            container = try! ModelContainer(
                for: TaskItem.self, Attachment.self, Comment.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            modelContext = ModelContext(container)
            modelContext.undoManager = sharedUndoManager
            finalModelContext = modelContext

            // We'll need to show the error to the user after UI is set up
            // Store the error to be shown later
            databaseError = error
        }
    }

    // MARK: - Step 3: Create CloudPreferences
    let finalPreferences: CloudPreferences
    if let customPreferences = preferences {
        finalPreferences = customPreferences
    } else if isTesting {
        // Create test preferences with time provider
        let store: KeyValueStorage = TestPreferences()
        store.set(18, forKey: StorageKeys.compassCheckTimeHour)
        store.set(0, forKey: StorageKeys.compassCheckTimeMinute)
        finalPreferences = CloudPreferences(store: store, timeProvider: finalTimeProvider)
        finalPreferences.daysOfCompassCheck = 42
    } else {
        // Create production preferences with time provider
        finalPreferences = CloudPreferences(
            store: CloudKeyValueStore(store: NSUbiquitousKeyValueStore.default), timeProvider: finalTimeProvider)
    }

    // Always set test streak value when testing, regardless of whether custom preferences were provided
    if isTesting {
        finalPreferences.daysOfCompassCheck = 42
    }

    // MARK: - Step 4: Create UI State Manager
    let uiState = UIStateManager()

    // MARK: - Step 5: Create Data Manager
    let dataManager = DataManager(modelContext: finalModelContext, timeProvider: finalTimeProvider)

    // MARK: - Step 6: Create Push Notification Manager with dependencies
    let pushNotificationManager = PushNotificationManager(
        preferences: finalPreferences, timeProvider: finalTimeProvider)

    // MARK: - Step 7: Create Compass Check Manager
    let compassCheckManager = CompassCheckManager(
        dataManager: dataManager,
        uiState: uiState,
        preferences: finalPreferences,
        timeProvider: finalTimeProvider,
        pushNotificationManager: pushNotificationManager,
        steps: compassCheckSteps
    )

    // MARK: - Step 8: Set up Cross-Component Dependencies
    uiState.newItemProducer = dataManager
    dataManager.priorityUpdater = finalPreferences
    dataManager.itemSelector = uiState
    dataManager.dataIssueReporter = uiState
    finalPreferences.onChange = compassCheckManager.onPreferencesChange

    // MARK: - Step 9: Initialize Data and Setup
    dataManager.loadData()
    uiState.showItem = false
    dataManager.mergeDataFromCentralStorage()

    // Show database error if one occurred during setup
    if let error = databaseError {
        uiState.showDatabaseError(error)
    }

    // Show any migration issues that occurred during setup
    let migrationIssues = getPendingMigrationIssues()
    for issue in migrationIssues {
        uiState.reportMigrationIssue(issue.message, details: issue.details)
    }

    if !isTesting {
        // Only set up notifications for production
        compassCheckManager.setupCompassCheckNotification()
    }

    // MARK: - Step 10: Return Complete App Components
    return AppComponents(
        modelContainer: container,
        modelContext: finalModelContext,
        preferences: finalPreferences,
        uiState: uiState,
        dataManager: dataManager,
        compassCheckManager: compassCheckManager,
        pushNotificationManager: pushNotificationManager,
        timeProvider: finalTimeProvider,
        timeProviderWrapper: TimeProviderWrapper(finalTimeProvider),
        isTesting: isTesting
    )
}

extension CloudPreferences: PriorityUpdater {
    public func updatePriorities(prioTasks: [TaskItem]) {
        let prios = prioTasks.count
        for i in 0..<prios {
            setPriority(nr: i + 1, value: prioTasks[i].title)
            setPriorityUUID(nr: i + 1, value: prioTasks[i].id)
        }
        if prios < 5 {
            for i in prios...4 {
                setPriority(nr: i + 1, value: "")
                setPriorityUUID(nr: i + 1, value: "")
            }
        }

        // Refresh widget timeline when priorities change
        WidgetCenter.shared.reloadAllTimelines()
    }
}
