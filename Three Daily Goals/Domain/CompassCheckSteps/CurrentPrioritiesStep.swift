//
//  CurrentPrioritiesStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

import tdgCoreMain

@MainActor
public struct CurrentPrioritiesStep: CompassCheckStep {
    public let id: String = "currentPriorities"
    public let name: String = "Review Current Priorities"
    public let description: String = "Review your current priority tasks and move them back to the open list."
    public let isSilent: Bool = false
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckCurrentPriorities())
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // Move all priority tasks to open list
        for task in dataManager.list(which: .priority) {
            dataManager.move(task: task, to: .open)
        }
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are priority tasks to review
        return !dataManager.list(which: .priority).isEmpty
    }
}
