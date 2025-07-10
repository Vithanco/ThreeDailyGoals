//
//  Comment.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData

public typealias Comment = SchemaLatest.Comment

extension Comment {
    func deleteComment() {
        modelContext?.delete(self)
        taskItem = nil
    }
}

extension Comment: Equatable, Comparable {
    public static func < (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.created > rhs.created
    }

    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.text == rhs.text && lhs.created == rhs.created && lhs.changed == rhs.changed
    }
}

extension Comment: Identifiable {
    public var id: Date {
        return created
    }
}
