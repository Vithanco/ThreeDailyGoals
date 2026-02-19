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
    case highEnergyBigTask = "high-energy-big-task"
    case lowEnergyBigTask = "low-energy-big-task"
    case highEnergySmallTask = "high-energy-small-task"
    case lowEnergySmallTask = "low-energy-small-task"

    public var id: String { rawValue }

    /// Initialize from a persisted raw value string, supporting both old and new formats.
    /// Old Eisenhower-style raw values are mapped to the new energy/effort cases.
    /// Use this instead of init?(rawValue:) when loading from persistent storage.
    public static func fromStoredValue(_ value: String) -> EnergyEffortQuadrant? {
        if let result = EnergyEffortQuadrant(rawValue: value) {
            return result
        }
        // Fall back to old Eisenhower-style raw values for backward compatibility
        switch value {
        case "urgent-important": return .highEnergyBigTask
        case "not-urgent-important": return .lowEnergyBigTask
        case "urgent-not-important": return .highEnergySmallTask
        case "not-urgent-not-important": return .lowEnergySmallTask
        default: return nil
        }
    }

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
        case .highEnergyBigTask:
            return .eemDeepWork
        case .lowEnergyBigTask:
            return .eemSteadyProgress
        case .highEnergySmallTask:
            return .eemSprintTasks
        case .lowEnergySmallTask:
            return .eemEasyWins
        }
    }

    /// SF Symbol icon for the quadrant
    public var icon: String {
        switch self {
        case .highEnergyBigTask:
            return imgEemDeepWork
        case .lowEnergyBigTask:
            return imgEemSteadyProgress
        case .highEnergySmallTask:
            return imgEemSprintTasks
        case .lowEnergySmallTask:
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
        case .highEnergyBigTask:
            return ["high-energy", "big-task"]
        case .lowEnergyBigTask:
            return ["low-energy", "big-task"]
        case .highEnergySmallTask:
            return ["high-energy", "small-task"]
        case .lowEnergySmallTask:
            return ["low-energy", "small-task"]
        }
    }

    /// Initialize from a task's existing tags
    public static func from(task: TaskItem) -> EnergyEffortQuadrant? {
        let taskTags = Set(task.tags)

        if taskTags.contains("high-energy") && taskTags.contains("big-task") {
            return .highEnergyBigTask
        } else if taskTags.contains("low-energy") && taskTags.contains("big-task") {
            return .lowEnergyBigTask
        } else if taskTags.contains("high-energy") && taskTags.contains("small-task") {
            return .highEnergySmallTask
        } else if taskTags.contains("low-energy") && taskTags.contains("small-task") {
            return .lowEnergySmallTask
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
            .highEnergyBigTask: DisplayRepresentation(
                title: "Deep Work",
                subtitle: "High Energy & Big Task"
            ),
            .lowEnergyBigTask: DisplayRepresentation(
                title: "Steady Progress",
                subtitle: "Low Energy & Big Task"
            ),
            .highEnergySmallTask: DisplayRepresentation(
                title: "Sprint Tasks",
                subtitle: "High Energy & Small Task"
            ),
            .lowEnergySmallTask: DisplayRepresentation(
                title: "Easy Wins",
                subtitle: "Low Energy & Small Task"
            ),
        ]
    }
}
