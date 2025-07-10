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
        let open = self.items.filter({$0.isActive}).filter({$0.dueUntil(date: due)})
        //        let pending = self.list(which: .pendingResponse).filter({$0.dueUntil(date: due)})
        //        open.append(contentsOf: pending)
        return open.sorted()
    }
    
    func moveAllPrioritiesToOpen(){
        for p in list(which: .priority) {
            move(task: p, to: .open)
        }
    }
    
    @MainActor
    func moveStateForward() {
     //   assert(showReviewDialog)
        switch stateOfCompassCheck {
        case .inform:
            if list(which: .priority).isEmpty {
                fallthrough
            } else {
                stateOfCompassCheck = .currentPriorities
            }
        case .currentPriorities:
            moveAllPrioritiesToOpen()
            if list(which: .pendingResponse).isEmpty {
                fallthrough
            } else {
                stateOfCompassCheck = .pending
            }
        case .pending:
            let dueSoon = dueDateSoon
            if dueSoon.isEmpty {
                fallthrough
            } else {
                stateOfCompassCheck = .dueDate
            }
        case .dueDate :
            for t in dueDateSoon {
                move(task: t, to: .priority)
            }
            stateOfCompassCheck = .review
        case .review:
            stateOfCompassCheck = .plan
        case .plan:
            endCompassCheck(didCompassCheck: true)
        }
        debugPrint("new state is: \(stateOfCompassCheck)")
    }
    
    var moveStateForwardText: String {
        if stateOfCompassCheck == .plan {
            return "Finish"
        }
        return "Next"
    }
    
    func cancelCompassCheck(){
        showCompassCheckDialog = false
        stateOfCompassCheck = .inform
    }
    
    func didLastCompassCheckHappenInCurrentCompassCheckInterval() -> Bool {
        let savedCompassCheckInterval = preferences.currentCompassCheckInterval
        let lastCompassCheck = preferences.lastCompassCheck
        return savedCompassCheckInterval.contains(lastCompassCheck)
    }
    
    func endCompassCheck(didCompassCheck : Bool){
        showCompassCheckDialog = false
        stateOfCompassCheck = .inform
        debugPrint("endCompassCheck, finished: \(didCompassCheck)")
        debugPrint("did check: \(preferences.didCompassCheckToday)")
        debugPrint("current interval: \(preferences.currentCompassCheckInterval)")
        debugPrint("next interval: \(preferences.nextCompassCheckTime)")
        let countedBefore = didLastCompassCheckHappenInCurrentCompassCheckInterval()
        debugPrint("counted before: \(countedBefore)")
        
        // setting last review date
        if didCompassCheck {
            if !countedBefore {
                debugPrint("current streak: \(preferences.daysOfCompassCheck)")
                preferences.daysOfCompassCheck = preferences.daysOfCompassCheck + 1
                if preferences.daysOfCompassCheck > preferences.longestStreak {
                    preferences.longestStreak = preferences.daysOfCompassCheck
                }
                debugPrint("current streak: \(preferences.daysOfCompassCheck), longest: \(preferences.longestStreak)")
            }
            debugPrint("----- set date -----")
            preferences.lastCompassCheck = Date.now
            debugPrint("lastCompassCheck: \(preferences.lastCompassCheck)")
            debugPrint("next interval: \(preferences.nextCompassCheckTime)")
            debugPrint("did check: \(preferences.didCompassCheckToday)")
        }
        
        let currentCompassCheckInterval = getCompassCheckInterval()
        debugPrint("currentCompassCheckInterval: \(currentCompassCheckInterval)")
        debugPrint("stored interval: \(preferences.currentCompassCheckInterval)")
        
        if currentCompassCheckInterval.intersection(with: preferences.currentCompassCheckInterval)?.duration ?? 0 < Seconds.fourHours {
            debugPrint("new Day")
            // new day!
            if !countedBefore{
                // reset the streak to 0
                debugPrint("reset streak")
                preferences.daysOfCompassCheck = didCompassCheck ? 1 : 0
            }
            preferences.currentCompassCheckInterval = currentCompassCheckInterval
        }
        updateUndoRedoStatus()
        killOldTasks()
    }
    
    func waitABit() {
        setupCompassCheckNotification(when: Date.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    var priorityTasks: [TaskItem]{
        return list(which: .priority)
    }
    
    
    
    func onPreferencesChange() {
        if preferences.didCompassCheckToday && stateOfCompassCheck == .inform {
            endCompassCheck(didCompassCheck: false)
        }
    }
    
    func compassCheckNow(){
        if !showCompassCheckDialog && stateOfCompassCheck == .inform{
            debugPrint("start compass check \(Date.now)")
            showCompassCheckDialog = true
        }
    }
    
    var nextRegularCompassCheckTime: Date {
        var result = self.preferences.compassCheckTime
        if getCal().isDate(preferences.lastCompassCheck, inSameDayAs: result) {
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
    
    func setupCompassCheckNotification(when: Date? = nil){
        scheduleSystemPushNotification(timing: preferences.compassCheckTimeComponents, model: self)
        if showCompassCheckDialog {
            return
        }
        if isTesting {
            return
        }
        let time = when ?? nextRegularCompassCheckTime
        
        showCompassCheckDialog = false
        timer.setTimer(forWhen: time ){
            
            Task {
                do {
                    if await self.showCompassCheckDialog {
                        return
                    }
                    await self.compassCheckNow()
                    await self.setupCompassCheckNotification()
                }
            }
        }
    }
    
    func deleteNotifications() {
        timer.cancelTimer()
        showCompassCheckDialog = false
    }
}
