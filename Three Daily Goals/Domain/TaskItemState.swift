//
//  TaskItemState.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/01/2024.
//

import Foundation


enum TaskItemState: Codable {
    case open
    case closed
    case graveyard
    case pendingResponse
}
    
extension TaskItemState : CustomStringConvertible {
    var description: String {
        switch self {
            case .closed: return "closed"
            case .graveyard: return "graveyard"
            case .open: return "open"
            case .pendingResponse: return "pending"
        }
    }
}
