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
    case dueDate
    case review
}

extension TaskManagerViewModel {
    var dueDateSoon: [TaskItem] {
        let due = getDate(inDays: 3)
        let open = self.list(which: .open).filter({$0.dueUntil(date: due)})
//        let pending = self.list(which: .pendingResponse).filter({$0.dueUntil(date: due)})
//        open.append(contentsOf: pending)
        return open.sorted()
    }
}


@Observable
final class ReviewModel{
    
    var taskModel: TaskManagerViewModel
    var stateOfReview: DialogState = .inform
    
    init(taskModel: TaskManagerViewModel) {
        self.taskModel = taskModel
    }
    
    func movePrioritiesToOpen(){
        for p in taskModel.list(which: .priority) {
            taskModel.move(task: p, to: .open)
        }
    }
    
    func closeAllPriorities(){
        for p in taskModel.list(which: .priority) {
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
            let dueSoon = taskModel.dueDateSoon
            if dueSoon.isEmpty {
                fallthrough
            } else {
                stateOfReview = .dueDate
            }
        case .dueDate :
            stateOfReview = .review
        case .review:
            endReview()
        }
    }
    
    var nameOfNextStep: String {
        if stateOfReview == .review {
            return "Finish"
        }
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
        taskModel.setupReviewNotification(when: Date.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    var accentColor: Color {
        return taskModel.accentColor
    }
    
    var priorityTasks: [TaskItem]{
        return taskModel.list(which: .priority)
    }
}


@MainActor
func dummyReviewModel(state: DialogState = .inform) -> ReviewModel {
    let model = ReviewModel(taskModel: dummyViewModel())
    model.stateOfReview = state
    return model
}
