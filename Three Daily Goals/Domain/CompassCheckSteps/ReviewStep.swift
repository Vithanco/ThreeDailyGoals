//
//  ReviewStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

import tdgCoreMain

public struct ReviewStep: CompassCheckStep {
    public let id: String = "review"
    public let name: String = "Set New Priorities"
    public let description: String = "Review and set your three daily priorities for the upcoming period."
    public let isSilent: Bool = false
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckNextPriorities())
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // No specific actions needed - user sets priorities in the view
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Review step is always available - it's where users set new priorities
        return true
    }
}
