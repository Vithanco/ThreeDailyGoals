//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import CloudKit
import CoreData
import Foundation
import SwiftData
import SwiftUI
import TagKit
//
//@MainActor
//@Observable
//@available(*, deprecated, message: "use the different managers instead.")
//final class TaskManagerViewModel {
//    var isTesting: Bool = false
//
//    // Import/Export
//    var jsonExportDoc: JSONWriteOnlyDoc?
//
//    var preferences: CloudPreferences
//    var uiState: UIStateManager
//    var dataManager: DataManager
//    var compassCheckManager: CompassCheckManager!
//    var cloudKitManager: CloudKitManager!
//
//    init(modelContext: Storage, preferences: CloudPreferences, uiState: UIStateManager, isTesting: Bool = false) {
//        self.preferences = preferences
//        self.uiState = uiState
//        self.dataManager = DataManager(modelContext: modelContext)
//        self.isTesting = isTesting
//
//        // Load initial data
//        dataManager.loadData()
//        uiState.showItem = false
//        dataManager.mergeDataFromCentralStorage()
//
//        // Initialize CloudKitManager with dependency injection
//        self.cloudKitManager = CloudKitManager(dataManager: dataManager, preferences: preferences)
//
//        // Set up dependency injection for priority updates
//        dataManager.priorityUpdater = cloudKitManager
//
//        // Set up dependency injection for item selection
//        dataManager.itemSelector = uiState
//
//        // Initialize CompassCheckManager
//        self.compassCheckManager = CompassCheckManager(
//            dataManager: dataManager, uiState: uiState, preferences: preferences, isTesting: isTesting)
//
//        preferences.onChange = compassCheckManager.onPreferencesChange
//        compassCheckManager.setupCompassCheckNotification()
//    }
//
//}
//
//@MainActor
//func dummyViewModel(loader: TestStorage.Loader? = nil, preferences: CloudPreferences? = nil)
//    -> TaskManagerViewModel
//{
//    // Note: This function is kept for backward compatibility with tests and previews
//    // In the future, these should be updated to use setupApp(isTesting: true) directly
//    let appComponents = setupApp(isTesting: true, loader: loader, preferences: preferences)
//    return TaskManagerViewModel(
//        modelContext: appComponents.modelContext,
//        preferences: appComponents.preferences,
//        uiState: appComponents.uiState,
//        isTesting: true)
//}
