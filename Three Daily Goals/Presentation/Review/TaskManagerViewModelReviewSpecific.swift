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
        let open = self.dataManager.items.filter({ $0.isActive }).filter({ $0.dueUntil(date: due) })
        //        let pending = self.list(which: .pendingResponse).filter({$0.dueUntil(date: due)})
        //        open.append(contentsOf: pending)
        return open.sorted()
    }

    func moveAllPrioritiesToOpen() {
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
        case .dueDate:
            for t in dueDateSoon {
                move(task: t, to: .priority)
            }
            stateOfCompassCheck = .review
        case .review:
            if os == .iOS {
                endCompassCheck(didFinishCompassCheck: true)
            } else {
                stateOfCompassCheck = .plan
            }
        case .plan:
            endCompassCheck(didFinishCompassCheck: true)
        }
        debugPrint("new state is: \(stateOfCompassCheck)")
    }

    var moveStateForwardText: String {
        if os == .iOS {
            if stateOfCompassCheck == .review {
                return "Finish"
            }
        } else {
            if stateOfCompassCheck == .plan {
                return "Finish"
            }
        }
        return "Next"
    }

    func cancelCompassCheck() {
        uiState.showCompassCheckDialog = false
        stateOfCompassCheck = .inform
    }

    func endCompassCheck(didFinishCompassCheck: Bool) {
        uiState.showCompassCheckDialog = false
        stateOfCompassCheck = .inform
        debugPrint("endCompassCheck, finished: \(didFinishCompassCheck)")
        debugPrint("did check already today?: \(preferences.didCompassCheckToday)")
        debugPrint("current interval: \(getCompassCheckInterval())")
        debugPrint("next check will be notified at: \(preferences.nextCompassCheckTime)")
        let didCCAlreadyHappenInCurrentInterval = preferences.didCompassCheckToday

        // setting last review date
        if didFinishCompassCheck {
            if !didCCAlreadyHappenInCurrentInterval {

                let secondsOfLastCCBeforeCurrentInterval: TimeInterval = getCompassCheckInterval().start
                    .timeIntervalSince(preferences.lastCompassCheck)
                debugPrint("secondsOfLastCCBeforeCurrentInterval: \(secondsOfLastCCBeforeCurrentInterval)")
                debugPrint("smaller than a day?: \(secondsOfLastCCBeforeCurrentInterval < Seconds.fullDay)")
                if !(0...Seconds.fullDay).contains(secondsOfLastCCBeforeCurrentInterval) {
                    // reset the streak to 0
                    debugPrint("reset streak")
                    preferences.daysOfCompassCheck = 0  // will soon be set to 1
                }
                debugPrint("current streak: \(preferences.daysOfCompassCheck)")
                preferences.daysOfCompassCheck = preferences.daysOfCompassCheck + 1
                if preferences.daysOfCompassCheck > preferences.longestStreak {
                    preferences.longestStreak = preferences.daysOfCompassCheck
                }
                debugPrint(
                    "current streak: \(preferences.daysOfCompassCheck), longest: \(preferences.longestStreak)"
                )
                debugPrint("----- set date -----")
                preferences.lastCompassCheck = Date.now
                debugPrint("lastCompassCheck: \(preferences.lastCompassCheck)")
                debugPrint("next interval: \(preferences.nextCompassCheckTime)")
                debugPrint("did check: \(preferences.didCompassCheckToday)")
            }
        }

        updateUndoRedoStatus()
        killOldTasks()
    }

    func waitABit() {
        setupCompassCheckNotification(when: Date.now.addingTimeInterval(Seconds.fiveMin))
    }

    var priorityTasks: [TaskItem] {
        return list(which: .priority)
    }

    func onPreferencesChange() {
        if preferences.didCompassCheckToday && stateOfCompassCheck == .inform {
            endCompassCheck(didFinishCompassCheck: false)
        }
    }

    func startCompassCheckNow() {
        preferences.setStreakText()
        if !uiState.showCompassCheckDialog && stateOfCompassCheck == .inform {
            debugPrint("start compass check \(Date.now)")
            uiState.showCompassCheckDialog = true
        }
    }

    var nextRegularCompassCheckTime: Date {
        var result = self.preferences.compassCheckTime
        if getCal().isDate(preferences.lastCompassCheck, inSameDayAs: result) {
            // review happened today, let's do it tomorrow
            result = addADay(result)
        } else {  // today's review missing
            if result < Date.now {
                //regular time passed by, now just do it in 5 minutes to allow app to fully load
                return Date.now.addingTimeInterval(Seconds.oneMin)
            }
        }
        return result
    }

    func setupCompassCheckNotification(when: Date? = nil) {
        scheduleSystemPushNotification(timing: preferences.compassCheckTimeComponents, model: self)
        if uiState.showCompassCheckDialog {
            return
        }
        if isTesting {
            return
        }
        if uiState.showInfoMessage || showExportDialog || showImportDialog || uiState.showSettingsDialog || uiState.showNewItemNameDialog {
            waitABit()
        }
        let time = when ?? nextRegularCompassCheckTime

        uiState.showCompassCheckDialog = false
        timer.setTimer(forWhen: time) {

            Task {
                do {
                    if await self.uiState.showCompassCheckDialog {
                        return
                    }
                    if await !self.preferences.didCompassCheckToday {
                        await self.startCompassCheckNow()
                    }
                    await self.setupCompassCheckNotification()
                }
            }
        }
    }

    func deleteNotifications() {
        timer.cancelTimer()
        uiState.showCompassCheckDialog = false
    }
}
