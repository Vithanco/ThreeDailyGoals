//
//  EnergyEffortMatrixStep.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import Foundation
import SwiftUI
import tdgCoreMain
import tdgCoreWidget

@MainActor
public struct EnergyEffortMatrixStep: @MainActor CompassCheckStep {
    public let id: String = "EnergyEffortMatrix"
    public let name: String = "Energy-Effort Matrix"
    public let description: String =
        "Categorize tasks by energy required and task size (inspired by the EnergyEffort Matrix)."

    public var isSilent: Bool {
        return false
    }

    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckEnergyEffortMatrix())
    }

    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // No automatic actions - categorization happens in the view
    }

    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show if there are active tasks without complete Energy-Effort tags that are old enough
        let now = timeProvider.now
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hoursBeforeReadyForClassification, to: now) ?? now

        let uncategorizedTasks = dataManager.allTasks.filter { task in
            task.isActive
            && !task.hasCompleteEnergyEffortTags
            && task.created < cutoffDate
        }
        return !uncategorizedTasks.isEmpty
    }

    @ViewBuilder
    public func configurationView() -> AnyView? {
        // No configuration needed for this step
        nil as AnyView?
    }
}
