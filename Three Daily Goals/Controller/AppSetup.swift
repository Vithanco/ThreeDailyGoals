import Foundation
import SwiftData
import SwiftUI

/// Struct containing all app components and managers
struct AppComponents {
    let modelContainer: ModelContainer
    let modelContext: Storage
    let preferences: CloudPreferences
    let uiState: UIStateManager
    let dataManager: DataManager
    let cloudKitManager: CloudKitManager
    let compassCheckManager: CompassCheckManager
    let isTesting: Bool
}

/// Set up the app with all necessary components
/// - Parameter isTesting: If true, creates a test setup with dummy data
/// - Returns: AppComponents struct containing all managers and components
@MainActor
func setupApp(isTesting: Bool, loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil) -> AppComponents
{
    guard isTesting else {
        return setupProductionApp()
    }
    return setupTestApp(loader: loader, preferences: preferences)
}

/// Set up the app for production use
@MainActor
private func setupProductionApp() -> AppComponents {
    // Create production storage
    let container = sharedModelContainer(inMemory: false, withCloud: true)
    let modelContext = ModelContext(container)

    // Create production preferences
    let preferences = CloudPreferences(store: NSUbiquitousKeyValueStore.default)

    // Create UI state manager
    let uiState = UIStateManager()

    // Create data manager
    let dataManager = DataManager(modelContext: modelContext)

    // Load initial data
    dataManager.loadData()
    uiState.showItem = false
    dataManager.mergeDataFromCentralStorage()

    // Create CloudKit manager with dependency injection
    let cloudKitManager = CloudKitManager(dataManager: dataManager, preferences: preferences)

    // Set up dependency injection for priority updates
    dataManager.priorityUpdater = cloudKitManager

    // Set up dependency injection for item selection
    dataManager.itemSelector = uiState

    // Create CompassCheck manager
    let compassCheckManager = CompassCheckManager(
        dataManager: dataManager,
        uiState: uiState,
        preferences: preferences,
        isTesting: false
    )

    // Set up preferences change handler
    preferences.onChange = compassCheckManager.onPreferencesChange
    compassCheckManager.setupCompassCheckNotification()

    return AppComponents(
        modelContainer: container,
        modelContext: modelContext,
        preferences: preferences,
        uiState: uiState,
        dataManager: dataManager,
        cloudKitManager: cloudKitManager,
        compassCheckManager: compassCheckManager,
        isTesting: false
    )
}

@MainActor
private func testPreferences() -> CloudPreferences {
    let store: KeyValueStorage = TestPreferences()
    store.set(18, forKey: .compassCheckTimeHour)
    store.set(0, forKey: .compassCheckTimeMinute)
    let result = CloudPreferences(store: store)
    result.daysOfCompassCheck = 42
    return result
}

/// Set up the app for testing
@MainActor
private func setupTestApp(loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil) -> AppComponents {
    // Create test container
    let container = sharedModelContainer(inMemory: true, withCloud: false)
    let modelContext = ModelContext(container)

    // For testing, we always use TestStorage - either with custom loader or default data
    let finalModelContext: Storage
    if let loader = loader {
        finalModelContext = TestStorage(loader: loader)
    } else {
        finalModelContext = TestStorage()  // Use default test data with 178 items
    }

    // Create test preferences
    let preferences = (preferences == nil) ? testPreferences() : preferences!

    // Create UI state manager
    let uiState = UIStateManager()

    // Create data manager
    let dataManager = DataManager(modelContext: finalModelContext)

    // Load initial data
    dataManager.loadData()
    uiState.showItem = false
    dataManager.mergeDataFromCentralStorage()

    // Create CloudKit manager with dependency injection
    let cloudKitManager = CloudKitManager(dataManager: dataManager, preferences: preferences)

    // Set up dependency injection for priority updates
    dataManager.priorityUpdater = cloudKitManager

    // Set up dependency injection for item selection
    dataManager.itemSelector = uiState

    // Create CompassCheck manager
    let compassCheckManager = CompassCheckManager(
        dataManager: dataManager,
        uiState: uiState,
        preferences: preferences,
        isTesting: true
    )

    // Set up preferences change handler
    preferences.onChange = compassCheckManager.onPreferencesChange
    compassCheckManager.setupCompassCheckNotification()

    return AppComponents(
        modelContainer: container,
        modelContext: modelContext,
        preferences: preferences,
        uiState: uiState,
        dataManager: dataManager,
        cloudKitManager: cloudKitManager,
        compassCheckManager: compassCheckManager,
        isTesting: true
    )
}
