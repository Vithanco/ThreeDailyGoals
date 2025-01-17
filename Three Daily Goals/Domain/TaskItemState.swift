//
//  TaskItemState.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/01/2024.
//

import Foundation
import SwiftUI

typealias TaskSorter = (TaskItem, TaskItem) -> Bool

public enum TaskItemState: Codable, Hashable, CaseIterable {
    case open
    case closed
    case dead
    case pendingResponse
    case priority
}
    
extension TaskItemState : CustomStringConvertible, Identifiable{
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

extension TaskItemState{
    var showCount: Bool {
        switch self {
            case .closed, .dead: return false
            case .open, .pendingResponse, .priority: return true
        }
    }
    
    var imageName: String {
        switch self {
            case .closed: return imgClosed
            case .dead: return imgGraveyard
            case .open: return imgOpen
            case .pendingResponse: return imgPendingResponse
            case .priority: return imgToday
        }
    }
    
    var image: Image {
        return Image(systemName: self.imageName)
    }
    
    var getLinkedListAccessibilityIdentifier: String {
        return self.description + "_LinkedList"
    }
    
    var getListAccessibilityIdentifier: String {
        return self.description + "_List"
    }
    
    var section: TaskSection {
        switch self {
            case .open : return secOpen
            case .closed: return secClosed
            case .dead: return secGraveyard
            case .priority: return secToday
            case .pendingResponse: return secPending
        }
    }
    
    fileprivate func oldestFirst (a: TaskItem,b: TaskItem) -> Bool {
        return a.changed < b.changed
    }
    
    fileprivate func youngestFirst (a: TaskItem,b: TaskItem) -> Bool {
        return a.changed > b.changed
    }
    
    var sorter: TaskSorter {
        switch self {
            case .closed, .dead: return youngestFirst
            case .open, .priority, .pendingResponse: return oldestFirst
        }
    }
    var subHeaders: [ListHeader] {
        switch self {
        case .open : return ListHeader.defaultListHeaders
        case .closed: return ListHeader.defaultListHeaders.reversed()
        case .dead: return ListHeader.defaultListHeaders.reversed()
        case .priority: return [ListHeader.all]
        case .pendingResponse: return ListHeader.defaultListHeaders
        }
    }
}
