//
//  ReviewSpecific.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/05/2024.
//

import Foundation
import os

extension TaskManagerViewModel {
    
    var dueDateSoon: [TaskItem] {
        let due = getDate(inDays: 3)
        let open = self.list(which: .open).filter({$0.dueUntil(date: due)})
        //        let pending = self.list(which: .pendingResponse).filter({$0.dueUntil(date: due)})
        //        open.append(contentsOf: pending)
        return open.sorted()
    }
    
    func moveAllPrioritiesToOpen(){
        for p in list(which: .priority) {
            move(task: p, to: .open)
        }
    }
    
    func moveStateForward() {
     //   assert(showReviewDialog)
        switch stateOfReview {
        case .inform:
            if list(which: .priority).isEmpty {
                fallthrough
            } else {
                stateOfReview = .currentPriorities
            }
        case .currentPriorities:
            moveAllPrioritiesToOpen()
            if list(which: .pendingResponse).isEmpty {
                fallthrough
            } else {
                stateOfReview = .pending
            }
        case .pending:
            let dueSoon = dueDateSoon
            if dueSoon.isEmpty {
                fallthrough
            } else {
                stateOfReview = .dueDate
            }
        case .dueDate :
            for t in dueDateSoon {
                move(task: t, to: .priority)
            }
            stateOfReview = .review
        case .review:
            stateOfReview = .plan
        case .plan:
            endReview(didReview: true)
        }
    }
    
    var nameOfNextStep: String {
        if stateOfReview == .review {
            return "Finish"
        }
        return "Next"
    }
    
    func cancelReview(){
        showReviewDialog = false
        stateOfReview = .inform
    }
    
    func didLastReviewHappenInCurrentReviewInterval() -> Bool {
        let savedReviewInterval = preferences.currentReviewInterval
        let lastReview = preferences.lastReview
        return savedReviewInterval.contains(lastReview)
    }
    
    func endReview(didReview : Bool){
        showReviewDialog = false
        stateOfReview = .inform
        
        let countedBefore = didLastReviewHappenInCurrentReviewInterval()
        
        // setting last review date
        if didReview {
            preferences.lastReview = Date.now
            if !countedBefore {
                preferences.daysOfReview = preferences.daysOfReview + 1
                if preferences.daysOfReview > preferences.longestStreak {
                    preferences.longestStreak = preferences.daysOfReview
                }
            }
        }
        
        let currentReviewInterval = getReviewInterval()
        
        if currentReviewInterval.intersection(with: preferences.currentReviewInterval)?.duration ?? 0 < Seconds.fourHours {
            // new day!
            if !countedBefore{
                // reset the streak to 0
                preferences.daysOfReview = didReview ? 1 : 0
            }
            preferences.currentReviewInterval = currentReviewInterval
        }
        updateUndoRedoStatus()
        killOldTasks()
    }
    
    func waitABit() {
        setupReviewNotification(when: Date.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    var priorityTasks: [TaskItem]{
        return list(which: .priority)
    }
    
    
    
    func onPreferencesChange() {
        if preferences.didReviewToday && stateOfReview == .inform {
            endReview(didReview: false)
        }
    }
    
    func reviewNow(){
        if !showReviewDialog && stateOfReview == .inform{
            debugPrint("start review \(Date.now)")
            showReviewDialog = true
        }
    }
    
    var nextRegularReviewTime: Date {
        var result = self.preferences.reviewTime
        if getCal().isDate(preferences.lastReview, inSameDayAs: result) {
            // review happened today, let's do it tomorrow
            result = addADay(result)
        } else { // today's review missing
            if result < Date.now {
                //regular time passed by, now just do it in 30 secs
                return Date.now.addingTimeInterval(Seconds.thirtySeconds)
            }
        }
        return result
    }
    
    func setupReviewNotification(when: Date? = nil){
        scheduleSystemPushNotification(timing: preferences.reviewTimeComponents, model: self)
        if showReviewDialog {
            return
        }
        if isTesting {
            return
        }
        let time = when ?? nextRegularReviewTime
        
        showReviewDialog = false
        timer.setTimer(forWhen: time ){
            
            Task {
                do {
                    if self.showReviewDialog {
                        return
                    }
                    self.reviewNow()
                    self.setupReviewNotification()
                }
            }
        }
    }
    
    func deleteNotifications() {
        timer.cancelTimer()
        showReviewDialog = false
    }
}
