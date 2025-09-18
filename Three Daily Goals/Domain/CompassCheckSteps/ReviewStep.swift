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
    
    public func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Review step is always available - it's where users set new priorities
        return true
    }
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckNextPriorities())
    }
    
    public func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // No specific actions needed - user sets priorities in the view
    }
    
    public func shouldSkip(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        return !isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider)
    }
}
