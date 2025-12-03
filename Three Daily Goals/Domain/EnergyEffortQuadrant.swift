//
//  EisenhowerQuadrant.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import Foundation
import SwiftUI
import tdgCoreMain

// MARK: - Quadrant Wording Constants

/// Display names, descriptions, colors, and icons for the Energy-Effort Matrix quadrants
/// (Inspired by the Eisenhower Matrix, adapted for execution planning)
public struct EnergyEffortQuadrantWording {
    // Q1: High Energy & Big Task
    public static let urgentImportantName = "Deep Work"
    public static let urgentImportantDescription = "High Energy & Big Task"
    public static let urgentImportantColor = Color.purple
    public static let urgentImportantIcon = "brain.head.profile"

    // Q2: Low Energy & Big Task
    public static let notUrgentImportantName = "Steady Progress"
    public static let notUrgentImportantDescription = "Low Energy & Big Task"
    public static let notUrgentImportantColor = Color.green
    public static let notUrgentImportantIcon = "tortoise.fill"

    // Q3: High Energy & Small Task
    public static let urgentNotImportantName = "Sprint Tasks"
    public static let urgentNotImportantDescription = "High Energy & Small Task"
    public static let urgentNotImportantColor = Color.orange
    public static let urgentNotImportantIcon = "bolt.fill"

    // Q4: Low Energy & Small Task
    public static let notUrgentNotImportantName = "Easy Wins"
    public static let notUrgentNotImportantDescription = "Low Energy & Small Task"
    public static let notUrgentNotImportantColor = Color.blue
    public static let notUrgentNotImportantIcon = "checkmark.circle.fill"
}

/// Represents the four quadrants of the Energy-Effort Matrix
public enum EnergyEffortQuadrant: String, CaseIterable, Identifiable {
    case urgentImportant = "urgent-important"
    case notUrgentImportant = "not-urgent-important"
    case urgentNotImportant = "urgent-not-important"
    case notUrgentNotImportant = "not-urgent-not-important"

    public var id: String { rawValue }

    /// Display name for the quadrant
    public var name: String {
        switch self {
        case .urgentImportant:
            return EnergyEffortQuadrantWording.urgentImportantName
        case .notUrgentImportant:
            return EnergyEffortQuadrantWording.notUrgentImportantName
        case .urgentNotImportant:
            return EnergyEffortQuadrantWording.urgentNotImportantName
        case .notUrgentNotImportant:
            return EnergyEffortQuadrantWording.notUrgentNotImportantName
        }
    }

    /// Full description of the quadrant
    public var description: String {
        switch self {
        case .urgentImportant:
            return EnergyEffortQuadrantWording.urgentImportantDescription
        case .notUrgentImportant:
            return EnergyEffortQuadrantWording.notUrgentImportantDescription
        case .urgentNotImportant:
            return EnergyEffortQuadrantWording.urgentNotImportantDescription
        case .notUrgentNotImportant:
            return EnergyEffortQuadrantWording.notUrgentNotImportantDescription
        }
    }

    /// Color for the quadrant
    public var color: Color {
        switch self {
        case .urgentImportant:
            return EnergyEffortQuadrantWording.urgentImportantColor
        case .notUrgentImportant:
            return EnergyEffortQuadrantWording.notUrgentImportantColor
        case .urgentNotImportant:
            return EnergyEffortQuadrantWording.urgentNotImportantColor
        case .notUrgentNotImportant:
            return EnergyEffortQuadrantWording.notUrgentNotImportantColor
        }
    }

    /// SF Symbol icon for the quadrant
    public var icon: String {
        switch self {
        case .urgentImportant:
            return EnergyEffortQuadrantWording.urgentImportantIcon
        case .notUrgentImportant:
            return EnergyEffortQuadrantWording.notUrgentImportantIcon
        case .urgentNotImportant:
            return EnergyEffortQuadrantWording.urgentNotImportantIcon
        case .notUrgentNotImportant:
            return EnergyEffortQuadrantWording.notUrgentNotImportantIcon
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
}
