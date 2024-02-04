//
//  ReviewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import Foundation
import SwiftUI


enum DialogState : String{
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
        switch stateOfReview {
            case .inform:
                if taskModel.list(which: .priority).isEmpty {
                    fallthrough
                } else {
                    stateOfReview = .currentPriorities
                }
            case .currentPriorities:
                if taskModel.list(which: .pendingResponse).isEmpty {
                    fallthrough
                } else {
                    stateOfReview = .pending
                }
            case .pending:
                stateOfReview = .review
            case .review:
                endReview()
        }
    }
    
    var nameOfNextStep: String {
        return "Next"
    }
    
    func cancelReview(){
        taskModel.showReviewDialog = false
        stateOfReview = .inform
    }
    
    func endReview(){
        stateOfReview = .inform
        taskModel.killOldTasks()
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


func dummyReviewModel(state: DialogState = .inform) -> ReviewModel {
    let model = ReviewModel(taskModel: dummyViewModel())
    model.stateOfReview = state
    return model
}
