//
//  PendingResponsesStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

struct PendingResponsesStep: CompassCheckStep {
    let id: String = "pending"
    
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are pending response tasks
        return !dataManager.list(which: .pendingResponse).isEmpty
    }
    
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckPendingResponses())
    }
    
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // No specific actions needed - user can close tasks in the view
    }
}
