//
//  MovePrioritiesToOpenStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import tdgCoreMain

@MainActor
public struct MovePrioritiesToOpenStep: CompassCheckStep {
    public let id: String = "movePrioritiesToOpen"
    public let name: String = "Move Priorities to Open"
    public let description: String = "Automatically moves all priority tasks back to the open list."
    
    /// This is a silent step - it executes automatically without user interaction
    public var isSilent: Bool {
        return true
    }
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        // Silent steps don't need a view, but we provide a minimal one for protocol compliance
        AnyView(
            Text("Moving priorities to open list...")
                .foregroundColor(.secondary)
        )
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // Move all priority tasks to open list
        for task in dataManager.list(which: .priority) {
            dataManager.move(task: task, to: .open)
        }
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only applicable if there are priority tasks to move
        return !dataManager.list(which: .priority).isEmpty
    }
}
