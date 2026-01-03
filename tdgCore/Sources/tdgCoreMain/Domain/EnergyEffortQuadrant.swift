//
//  EnergyEffortQuadrant.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import AppIntents
import Foundation
import SwiftUI
import tdgCoreWidget

/// Represents the four quadrants of the Energy-Effort Matrix
/// (Inspired by the EnergyEffort Matrix, adapted for execution planning)
/// Colors chosen to be distinct from task state colors (orange/blue/green/yellow/brown)
/// Using muted/toned down colors for a more professional appearance
///
/// Note: Display names and descriptions are defined in the AppEnum conformance below
/// and accessed via instance properties
public enum EnergyEffortQuadrant: String, CaseIterable, Identifiable {
    case urgentImportant = "urgent-important"
    case notUrgentImportant = "not-urgent-important"
    case urgentNotImportant = "urgent-not-important"
    case notUrgentNotImportant = "not-urgent-not-important"

    public var id: String { rawValue }

    /// Display name for the quadrant (as LocalizedStringResource)
    /// Reads from AppEnum caseDisplayRepresentations (single source of truth)
    public var nameResource: LocalizedStringResource {
        Self.caseDisplayRepresentations[self]?.title ?? "Unknown"
    }

    /// Display name for the quadrant (as String for backwards compatibility)
    public var name: String {
        String(localized: nameResource)
    }

    /// Full description of the quadrant (as LocalizedStringResource)
    /// Reads from AppEnum caseDisplayRepresentations (single source of truth)
    public var descriptionResource: LocalizedStringResource {
        Self.caseDisplayRepresentations[self]?.subtitle ?? "Unknown"
    }

    /// Full description of the quadrant (as String for backwards compatibility)
    public var description: String {
        String(localized: descriptionResource)
    }

    /// Color for the quadrant
    public var color: Color {
        switch self {
        case .urgentImportant:
            return .eemDeepWork
        case .notUrgentImportant:
            return .eemSteadyProgress
        case .urgentNotImportant:
            return .eemSprintTasks
        case .notUrgentNotImportant:
            return .eemEasyWins
        }
    }

    /// SF Symbol icon for the quadrant
    public var icon: String {
        switch self {
        case .urgentImportant:
            return imgEemDeepWork
        case .notUrgentImportant:
            return imgEemSteadyProgress
        case .urgentNotImportant:
            return imgEemSprintTasks
        case .notUrgentNotImportant:
            return imgEemEasyWins
        }
    }

    /// Whether this quadrant requires a delivery time
    public var requiresDeliveryTime: Bool {
        return false  // No delivery time required for Energy-Effort Matrix
    }

    /// Tags to apply for this quadrant
    public var tags: [String] {
        switch self {
        case .urgentImportant:
            return ["high-energy", "big-task"]
        case .notUrgentImportant:
            return ["low-energy", "big-task"]
        case .urgentNotImportant:
            return ["high-energy", "small-task"]
        case .notUrgentNotImportant:
            return ["low-energy", "small-task"]
        }
    }

    /// Initialize from a task's existing tags
    public static func from(task: TaskItem) -> EnergyEffortQuadrant? {
        let taskTags = Set(task.tags)

        if taskTags.contains("high-energy") && taskTags.contains("big-task") {
            return .urgentImportant
        } else if taskTags.contains("low-energy") && taskTags.contains("big-task") {
            return .notUrgentImportant
        } else if taskTags.contains("high-energy") && taskTags.contains("small-task") {
            return .urgentNotImportant
        } else if taskTags.contains("low-energy") && taskTags.contains("small-task") {
            return .notUrgentNotImportant
        }

        return nil
    }
}

/// Extension to TaskItem for Energy-Effort Matrix operations
extension TaskItem {

    /// Apply Energy-Effort quadrant tags to the task
    public func applyEnergyEffortQuadrant(_ quadrant: EnergyEffortQuadrant) {
        let tags = quadrant.tags
        // tags array always has exactly 2 elements: [energyTag, effortTag]
        applyEnergyEffortTags(energyTag: tags[0], effortTag: tags[1])
    }

    /// Clear all Energy-Effort Matrix tags from the task
    public func clearEnergyEffortTags() {
        // Remove all energy and effort tags
        let matrixTags = ["high-energy", "low-energy", "big-task", "small-task"]
        self.tags.removeAll { matrixTags.contains($0) }
    }
}

// MARK: - AppEnum Conformance

extension EnergyEffortQuadrant: AppEnum {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Energy-Effort Quadrant")
    }

    /// Display representations for each quadrant case
    /// This is the single source of truth for quadrant names and descriptions
    public static var caseDisplayRepresentations: [EnergyEffortQuadrant: DisplayRepresentation] {
        [
            .urgentImportant: DisplayRepresentation(
                title: "Deep Work",
                subtitle: "High Energy & Big Task"
            ),
            .notUrgentImportant: DisplayRepresentation(
                title: "Steady Progress",
                subtitle: "Low Energy & Big Task"
            ),
            .urgentNotImportant: DisplayRepresentation(
                title: "Sprint Tasks",
                subtitle: "High Energy & Small Task"
            ),
            .notUrgentNotImportant: DisplayRepresentation(
                title: "Easy Wins",
                subtitle: "Low Energy & Small Task"
            ),
        ]
    }
}
