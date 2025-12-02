//
//  EisenhowerMatrixConsistencyStep.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import Foundation
import SwiftUI
import tdgCoreMain

@MainActor
public struct EisenhowerMatrixConsistencyStep: CompassCheckStep {
    public let id: String = "eisenhowerMatrixConsistency"
    public let name: String = "Eisenhower Matrix Consistency"
    public let description: String =
        "Ensures tasks don't have conflicting Eisenhower Matrix tags (e.g., both urgent and non-urgent)."

    /// This is a silent step - it executes automatically without user interaction
    public var isSilent: Bool {
        return true
    }

    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        // Silent steps don't need a view, but we provide a minimal one for protocol compliance
        AnyView(
            Text("Checking Eisenhower Matrix tag consistency...")
                .foregroundColor(.secondary)
        )
    }

    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // Get all active tasks
        let activeTasks = dataManager.allTasks.filter { $0.isActive }

        var fixedCount = 0

        for task in activeTasks {
            var tagsChanged = false
            var currentTags = task.tags

            // Check urgency dimension: remove both tags if both are present
            if currentTags.contains("urgent") && currentTags.contains("non-urgent") {
                currentTags.removeAll { $0 == "urgent" || $0 == "non-urgent" }
                tagsChanged = true
            }

            // Check importance dimension: remove both tags if both are present
            if currentTags.contains("important") && currentTags.contains("non-important") {
                currentTags.removeAll { $0 == "important" || $0 == "non-important" }
                tagsChanged = true
            }

            // Update task if tags were changed
            if tagsChanged {
                task.tags = currentTags
                fixedCount += 1
            }
        }

        if fixedCount > 0 {
            debugPrint("EisenhowerMatrixConsistencyStep: Fixed \(fixedCount) tasks with conflicting Eisenhower Matrix tags")
        }
    }

    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // This step is always applicable - it can always check for tag conflicts
        return true
    }

    @ViewBuilder
    public func configurationView() -> AnyView? {
        // No configuration needed for this step
        nil as AnyView?
    }
}
