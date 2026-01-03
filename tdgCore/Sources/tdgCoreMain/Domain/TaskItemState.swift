//
//  TaskItemState.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/01/2024.
//

import Foundation
import SwiftUI

public typealias TaskSorter = (TaskItem, TaskItem) -> Bool

public enum TaskItemState: Codable, Hashable, CaseIterable, Sendable, Equatable {
    case open
    case closed
    case dead
    case pendingResponse
    case priority
}

extension TaskItemState: CustomStringConvertible, Identifiable {
    public var description: String {
        switch self {
        case .closed: return "closed"
        case .dead: return "graveyard"
        case .open: return "open"
        case .pendingResponse: return "pending"
        case .priority: return "priority"
        }
    }
    public var id: String {
        return self.description
    }
}

extension TaskItemState {
    public var showCount: Bool {
        switch self {
        case .closed, .dead: return false
        case .open, .pendingResponse, .priority: return true
        }
    }

    // List-specific colors
    public var color: Color {
        switch self {
        case .priority: return Color.priority
        case .open: return Color.open
        case .pendingResponse: return Color.pendingResponse
        case .closed: return Color.closed
        case .dead: return Color.dead
        }
    }

    public var imageName: String {
        switch self {
        case .closed: return imgClosed
        case .dead: return imgGraveyard
        case .open: return imgOpen
        case .pendingResponse: return imgPendingResponse
        case .priority: return imgPriority
        }
    }

    public var image: Image {
        return Image(systemName: self.imageName)
    }

    public var getLinkedListAccessibilityIdentifier: String {
        return self.description + "_LinkedList"
    }

    public var getListAccessibilityIdentifier: String {
        return self.description + "_List"
    }

    public var section: TaskSection {
        switch self {
        case .open: return secOpen
        case .closed: return secClosed
        case .dead: return secGraveyard
        case .priority: return secToday
        case .pendingResponse: return secPending
        }
    }

    public static func oldestFirst(a: TaskItem, b: TaskItem) -> Bool {
        return a.changed < b.changed
    }

    public static func youngestFirst(a: TaskItem, b: TaskItem) -> Bool {
        return a.changed > b.changed
    }

    public var sorter: TaskSorter {
        switch self {
        case .closed, .dead: return TaskItemState.youngestFirst
        case .open, .priority, .pendingResponse: return TaskItemState.oldestFirst
        }
    }
    public var subHeaders: [ListHeader] {
        switch self {
        case .open: return ListHeader.defaultListHeaders
        case .closed: return ListHeader.defaultListHeaders.reversed()
        case .dead: return ListHeader.defaultListHeaders.reversed()
        case .priority: return [ListHeader.all]
        case .pendingResponse: return ListHeader.defaultListHeaders
        }
    }
}

// MARK: - Task State Color Extensions
extension TaskItemState {

    var stateColorLight: Color {
        return color.opacity(0.1)
    }

    var stateColorMedium: Color {
        return color.opacity(0.3)
    }
}

extension TaskItem {
    var color: Color {
        return self.state.color
    }
}
