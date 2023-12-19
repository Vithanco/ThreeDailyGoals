//
//  DailyTasks.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation
import SwiftData


@Model
final class DailyTasks: ObservableObject, Identifiable {
    var day: Date  = Date.now
    
    @Relationship(deleteRule: .nullify) var priorities: [TaskItem]? = [TaskItem]()

    
    init() {
    }
    
    var id: Date {
        return day
    }
}
