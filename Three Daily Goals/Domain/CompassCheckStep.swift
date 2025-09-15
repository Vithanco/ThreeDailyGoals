//
//  CompassCheckStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

@MainActor
/// Protocol defining the interface for Compass Check steps
protocol CompassCheckStep: Equatable {
    /// Unique identifier for this step
    var id: String { get }
    
    /// Human-readable display name for this step
    var name: String { get }
    
    /// Whether the precondition for this step is fulfilled
    /// For example, if there are no priority tasks, we might skip the currentPriorities step
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool
    
    /// The view to display for this step
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView
    
    /// Actions to perform when moving to the next step
    /// This is where step-specific logic like moving tasks between states happens
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider)
    
    /// Whether this step should be skipped based on current conditions
    func shouldSkip(dataManager: DataManager, timeProvider: TimeProvider) -> Bool
}

/// Default implementations for common functionality
extension CompassCheckStep {
    func shouldSkip(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        return !isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider)
    }
}
