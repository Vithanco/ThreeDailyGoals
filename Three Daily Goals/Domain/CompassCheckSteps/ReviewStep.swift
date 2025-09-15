//
//  ReviewStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

struct ReviewStep: CompassCheckStep {
    let id: String = "review"
    let name: String = "Set New Priorities"
    
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Review step is always available - it's where users set new priorities
        return true
    }
    
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckNextPriorities())
    }
    
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // No specific actions needed - user sets priorities in the view
    }
}
