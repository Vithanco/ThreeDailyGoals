//
//  Item.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData


enum TaskItemState: Codable {
    case open
    case closed
    case graveyard
}

@Model
final class TaskItem : ObservableObject {
    var created: Date
    var changed: Date
    var closed: Date?
    var title: String {
        didSet {
            changed = Date.now
        }
    }
    var details: String {
        didSet {
            changed = Date.now
        }
    }
    var state: TaskItemState {
        didSet {
            changed = Date.now
            if state == .closed {
                closed = Date.now
            }
            if state == .open {
                closed = nil
            }
            if state == .graveyard {
                closed = nil
            }
        }
    }
    @Relationship(deleteRule: .cascade) var comments = [Comment]()

    init() {
        let now = Date.now
        self.created = now
        self.changed = now
        self.closed = nil
        self.title = "I need to ..."
        self.details = "(no details yet)"
        self.state = .open
    }
}


