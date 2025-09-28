//
//  CompassCheckStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import tdgCoreMain
import SwiftUI

@MainActor
/// Protocol defining the interface for Compass Check steps
public protocol CompassCheckStep: Equatable {
    /// Unique identifier for this step
    var id: String { get }
    
    /// Human-readable display name for this step
    var name: String { get }
    
    /// The view to display for this step
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView
    
    /// Actions to perform when this step is executed
    /// This is where step-specific logic like moving tasks between states happens
    func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences)
    
    /// Whether this step is applicable based on current conditions
    /// For example, if there are no priority tasks, the currentPriorities step is not applicable
    func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool
    
    /// Whether this step is silent (doesn't require user interaction)
    /// Silent steps are executed automatically without showing a UI
    var isSilent: Bool { get }
}

/// Default implementations for common functionality
extension CompassCheckStep {
    func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        return true
    }
    
    /// Default implementation: steps are not silent by default
    var isSilent: Bool {
        return false
    }
    
    func act(
        dataManager: Three_Daily_Goals.DataManager,
        timeProvider: any tdgCoreWidget.TimeProvider,
        preferences: tdgCoreWidget.CloudPreferences
    ) {
        // nothing to be done
    }
}
