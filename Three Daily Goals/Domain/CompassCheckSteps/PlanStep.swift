//
//  PlanStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import tdgCoreMain

public struct PlanStep: CompassCheckStep {

    public let id: String = "plan"
    public let name: String = "Plan Day"
    public let isSilent: Bool = false
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckPlanDay(date: compassCheckManager.timeProvider.getCompassCheckInterval().end))
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // No specific actions needed - planning happens in the view
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Plan step is only available on macOS (not iOS)
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

