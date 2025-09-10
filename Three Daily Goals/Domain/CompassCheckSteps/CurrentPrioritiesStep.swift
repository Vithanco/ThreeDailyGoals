//
//  CurrentPrioritiesStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

@MainActor
struct CurrentPrioritiesStep: CompassCheckStep {
    let id: String = "currentPriorities"
    
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are priority tasks to review
        return !dataManager.list(which: .priority).isEmpty
    }
    
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckCurrentPriorities())
    }
    
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // Move all priority tasks to open list
        for task in dataManager.list(which: .priority) {
            dataManager.move(task: task, to: .open)
        }
    }
}
