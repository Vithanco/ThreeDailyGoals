//
//  Comment.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftData
import Foundation

typealias Comment = SchemaLatest.Comment

extension Comment {
    func deleteComment() {
        modelContext?.delete(self)
        taskItem = nil
    }
}

extension Comment : Equatable, Comparable {

    static func < (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.created > rhs.created
    }
}


extension Comment: Identifiable {
    var id: Date {
        return created
    }
}
