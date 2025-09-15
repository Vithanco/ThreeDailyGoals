//
//  PlanStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

struct PlanStep: CompassCheckStep {

    let id: String = "plan"
    let name: String = "Plan Day"
    
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Plan step is only available on macOS (not iOS)
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckPlanDay(date: compassCheckManager.timeProvider.getCompassCheckInterval().end))
    }
    
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // No specific actions needed - planning happens in the view
    }
}

