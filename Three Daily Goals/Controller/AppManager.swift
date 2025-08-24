import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppManager {
    let modelContext: Storage
    let preferences: CloudPreferences
    let uiState: UIStateManager
    let dataManager: DataManager
    let cloudKitManager: CloudKitManager
    let compassCheckManager: CompassCheckManager
    
    init(modelContext: Storage, preferences: CloudPreferences, uiState: UIStateManager, isTesting: Bool = false) {
        self.modelContext = modelContext
        self.preferences = preferences
        self.uiState = uiState
        
        // Initialize DataManager
        self.dataManager = DataManager(modelContext: modelContext)
        
        // Load initial data
        dataManager.loadData()
        uiState.showItem = false
        dataManager.mergeDataFromCentralStorage()
        
        // Initialize CloudKitManager with dependency injection
        self.cloudKitManager = CloudKitManager(dataManager: dataManager, preferences: preferences)
        
        // Set up dependency injection for priority updates
        dataManager.priorityUpdater = cloudKitManager
        
        // Initialize CompassCheckManager
        self.compassCheckManager = CompassCheckManager(dataManager: dataManager, uiState: uiState, preferences: preferences, isTesting: isTesting)
        
        // Set up preferences change handler
        preferences.onChange = compassCheckManager.onPreferencesChange
        compassCheckManager.setupCompassCheckNotification()
    }
    
    // Factory method for testing
    static func createForTesting(loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil) -> AppManager {
        let testStorage = loader == nil ? TestStorage() : TestStorage(loader: loader!)
        return AppManager(
            modelContext: testStorage, 
            preferences: preferences ?? dummyPreferences(), 
            uiState: UIStateManager(),
            isTesting: true)
    }
}
