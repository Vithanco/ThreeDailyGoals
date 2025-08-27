import CloudKit
import Foundation
import SwiftData

@MainActor
@Observable
//TODO what did ChatGPT do here? This has to go
final class CloudKitManager: @preconcurrency PriorityUpdater {
    let dataManager: DataManager
    let preferences: CloudPreferences

    init(dataManager: DataManager, preferences: CloudPreferences) {
        self.dataManager = dataManager
        self.preferences = preferences
    }

    var isProductionEnvironment: Bool {
        return CKContainer.isProductionEnvironment
    }

    func updatePriorities() {
        if let prioTasks = dataManager.lists[.priority] {
            let prios = prioTasks.count
            for i in 0..<prios {
                preferences.setPriority(nr: i + 1, value: prioTasks[i].title)
            }
            if prios < 5 {
                for i in prios...4 {
                    preferences.setPriority(nr: i + 1, value: "")
                }
            }
        }
    }
}
