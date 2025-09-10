//
//  InformStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

struct InformStep: CompassCheckStep {
    let id: String = "inform"
    
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Inform step is always available - it's the starting point
        return true
    }
    
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckInformView())
    }
    
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // No specific actions needed for inform step
    }
}
