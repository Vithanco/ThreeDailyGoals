//
//  CurrentPrioritiesStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

import tdgCoreMain

@MainActor
public struct CurrentPrioritiesStep: CompassCheckStep {
    public let id: String = "currentPriorities"
    public let name: String = "Review Current Priorities"
    
    public func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are priority tasks to review
        return !dataManager.list(which: .priority).isEmpty
    }
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckCurrentPriorities())
    }
    
    public func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // Move all priority tasks to open list
        for task in dataManager.list(which: .priority) {
            dataManager.move(task: task, to: .open)
        }
    }
    
    public func shouldSkip(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        return !isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider)
    }
}
