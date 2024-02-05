//
//  TaskItemState.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/01/2024.
//

import Foundation


enum TaskItemState: Codable, Hashable, CaseIterable {
    case open
    case closed
    case dead
    case pendingResponse
    case priority
}
    
extension TaskItemState : CustomStringConvertible {
    var description: String {
        switch self {
            case .closed: return "closed"
            case .dead: return "graveyard"
            case .open: return "open"
            case .pendingResponse: return "pending"
            case .priority: return "priority"
        }
    }
    
    var showCount: Bool {
        switch self {
            case .closed, .dead: return false
            case .open, .pendingResponse, .priority: return true
        }
    }
}
