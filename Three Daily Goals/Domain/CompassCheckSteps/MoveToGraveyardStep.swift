//
//  MoveToGraveyardStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import tdgCoreMain

@MainActor
public struct MoveToGraveyardStep: CompassCheckStep {
    public let id: String = "moveToGraveyard"
    public let name: String = "Move unused Tasks to Graveyard"
    
    /// This is a silent step - it executes automatically without user interaction
    public var isSilent: Bool {
        return true
    }
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        // Silent steps don't need a view, but we provide a minimal one for protocol compliance
        AnyView(
            Text("Moving unused tasks to graveyard...")
                .foregroundColor(.secondary)
        )
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // This is where the actual work happens - move old tasks to graveyard
        let killedCount = dataManager.killOldTasks(expireAfter: preferences.expiryAfter, preferences: preferences)
        debugPrint("MoveToGraveyardStep: Moved \(killedCount) old tasks to graveyard")
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // This step is always applicable - it can always check for old tasks
        return true
    }
}
