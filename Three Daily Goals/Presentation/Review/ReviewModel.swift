//
//  ReviewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import Foundation
import SwiftUI


enum DialogState {
    case inform
    case currentPriorities
    case pending
    case review
}

@Observable
final class ReviewModel{
    
    var taskModel: TaskManagerViewModel
    var stateOfReview: DialogState = .inform
    
    init(taskModel: TaskManagerViewModel) {
        self.taskModel = taskModel
    }
    
    func movePrioritiesToOpen(){
        for p in taskModel.priorityTasks {
            taskModel.move(task: p, to: .open)
        }
    }
    
    func closeAllPriorities(){
        for p in taskModel.priorityTasks {
            taskModel.move(task: p, to: .closed)
        }
    }
    
    func moveStateForward() {
        if stateOfReview == .inform && !taskModel.list(which: .priority).isEmpty {
            stateOfReview = .currentPriorities
        } else if stateOfReview == .currentPriorities && !taskModel.list(which: .pendingResponse).isEmpty{
            stateOfReview = .pending
        } else {
            stateOfReview = .review
        }
    }
    
    var nameOfNextStep: String {
        switch stateOfReview {
            case .inform:
                return "Review Current Priorities"
            case .currentPriorities:
                return "Pending Tasks"
            case .pending:
                return "Next Priorities"
            case .review:
                return "Done"
        }
    }
    
    func cancelReview(){
        taskModel.showReviewDialog = false
        stateOfReview = .inform
    }
    
    func endReview(){
        stateOfReview = .inform
        taskModel.endReview()
    }
    
    func waitABit() {
        taskModel.setupReviewNotification(when: Date.now.addingTimeInterval(60*5))
    }
    
    
    var accentColor: Color {
        return taskModel.accentColor
    }
    
    var priorityTasks: [TaskItem]{
        return taskModel.list(which: .priority)
    }
}


func dummyReviewModel() -> ReviewModel {
    return ReviewModel(taskModel: TaskManagerViewModel(modelContext: TestStorage()))
}
