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
    let compassCheckManager: CompassCheckManager
    let timeProvider: TimeProvider
    let timeProviderWrapper: TimeProviderWrapper
    let isTesting: Bool
}

/// Set up the app with all necessary components
/// - Parameter isTesting: If true, creates a test setup with dummy data
/// - Parameter timeProvider: Optional TimeProvider. If nil, creates RealTimeProvider for production or MockTimeProvider for testing
/// - Parameter loader: Optional test data loader
/// - Parameter preferences: Optional custom preferences for testing
/// - Returns: AppComponents struct containing all managers and components
@MainActor
func setupApp(isTesting: Bool, timeProvider: TimeProvider? = nil, loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil) -> AppComponents {
    
    // MARK: - Step 1: Create TimeProvider (needed by everything)
    let finalTimeProvider = timeProvider ?? (isTesting ? MockTimeProvider(fixedNow: Date.now) : RealTimeProvider())
    
    // MARK: - Step 2: Create Storage Layer
    let container: ModelContainer
    let modelContext: ModelContext
    let finalModelContext: Storage
    
    if isTesting {
        // Test setup
        container = sharedModelContainer(inMemory: true, withCloud: false)
        modelContext = ModelContext(container)
        
        // Use TestStorage with custom loader or default data
        if let loader = loader {
            finalModelContext = TestStorage(loader: loader, timeProvider: finalTimeProvider)
        } else {
            finalModelContext = TestStorage(timeProvider: finalTimeProvider)  // Use default test data with 178 items
        }
    } else {
        // Production setup
        container = sharedModelContainer(inMemory: false, withCloud: true)
        modelContext = ModelContext(container)
        finalModelContext = modelContext
    }
    
    // MARK: - Step 3: Create CloudPreferences
    let finalPreferences: CloudPreferences
    if let customPreferences = preferences {
        finalPreferences = customPreferences
    } else if isTesting {
        // Create test preferences with time provider
        let store: KeyValueStorage = TestPreferences()
        store.set(18, forKey: .compassCheckTimeHour)
        store.set(0, forKey: .compassCheckTimeMinute)
        finalPreferences = CloudPreferences(store: store, timeProvider: finalTimeProvider)
        finalPreferences.daysOfCompassCheck = 42
    } else {
        // Create production preferences with time provider
        finalPreferences = CloudPreferences(store: NSUbiquitousKeyValueStore.default, timeProvider: finalTimeProvider)
    }
    
    // MARK: - Step 4: Create UI State Manager
    let uiState = UIStateManager()
    
    // MARK: - Step 5: Create Data Manager
    let dataManager = DataManager(modelContext: finalModelContext, timeProvider: finalTimeProvider)
    
    // MARK: - Step 6: Create Compass Check Manager
    let compassCheckManager = CompassCheckManager(
        dataManager: dataManager,
        uiState: uiState,
        preferences: finalPreferences,
        timeProvider: finalTimeProvider,
        isTesting: isTesting
    )
    
    // MARK: - Step 7: Set up Cross-Component Dependencies
    uiState.newItemProducer = dataManager
    dataManager.priorityUpdater = finalPreferences
    dataManager.itemSelector = uiState
    finalPreferences.onChange = compassCheckManager.onPreferencesChange
    
    // MARK: - Step 8: Initialize Data and Setup
    dataManager.loadData()
    uiState.showItem = false
    dataManager.mergeDataFromCentralStorage()
    
    if !isTesting {
        // Only set up notifications for production
        compassCheckManager.setupCompassCheckNotification()
    }
    
    // MARK: - Step 9: Return Complete App Components
    return AppComponents(
        modelContainer: container,
        modelContext: finalModelContext,
        preferences: finalPreferences,
        uiState: uiState,
        dataManager: dataManager,
        compassCheckManager: compassCheckManager,
        timeProvider: finalTimeProvider,
        timeProviderWrapper: TimeProviderWrapper(finalTimeProvider),
        isTesting: isTesting
    )
}

extension CloudPreferences : @preconcurrency PriorityUpdater {
    func updatePriorities(prioTasks: [TaskItem]) {
        let prios = prioTasks.count
        for i in 0..<prios {
            setPriority(nr: i + 1, value: prioTasks[i].title)
        }
        if prios < 5 {
            for i in prios...4 {
                setPriority(nr: i + 1, value: "")
            }
        }
    }
}
