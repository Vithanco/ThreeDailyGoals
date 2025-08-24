import Foundation
import SwiftUI
import SwiftData

/// Struct containing all app components and managers
struct AppComponents {
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
func setupApp(isTesting: Bool = false) -> AppComponents {
    if isTesting {
        return setupTestApp()
    } else {
        return setupProductionApp()
    }
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
        modelContext: modelContext,
        preferences: preferences,
        uiState: uiState,
        dataManager: dataManager,
        cloudKitManager: cloudKitManager,
        compassCheckManager: compassCheckManager,
        isTesting: false
    )
}

/// Set up the app for testing
@MainActor
private func setupTestApp() -> AppComponents {
    // Create test storage
    let testStorage = TestStorage()
    
    // Create test preferences
    let preferences = CloudPreferences(store: TestPreferences())
    
    // Create UI state manager
    let uiState = UIStateManager()
    
    // Create data manager
    let dataManager = DataManager(modelContext: testStorage)
    
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
        modelContext: testStorage,
        preferences: preferences,
        uiState: uiState,
        dataManager: dataManager,
        cloudKitManager: cloudKitManager,
        compassCheckManager: compassCheckManager,
        isTesting: true
    )
}


