//
//  CompassCheckManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/05/2024.
//

import Foundation
import SwiftUI
import os

enum CompassCheckState: String {
    case inform
    case currentPriorities
    case pending
    case dueDate
    case review
    case plan
}

@MainActor
@Observable
final class CompassCheckManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CompassCheckManager.self)
    )

    private var notificationTask: Task<Void, Never>? {
        willSet {
            notificationTask?.cancel()
        }
    }
    
    private var syncCheckTimer: Timer?

    let timer: CompassCheckTimer = .init()

    var state: CompassCheckState = .inform
    
    // Pause functionality
    var isPaused: Bool = false
    var pausedState: CompassCheckState = .inform

    // Dependencies
    private let dataManager: DataManager
    private let uiState: UIStateManager
    private let preferences: CloudPreferences
    private let timeProvider: TimeProvider
    private let pushNotificationManager: PushNotificationManager

    var os: SupportedOS {
        #if os(iOS)
            if isLargeDevice {
                return .ipadOS
            }
            return .iOS
        #elseif os(macOS)
            return .macOS
        #endif
    }

    init(dataManager: DataManager, uiState: UIStateManager, preferences: CloudPreferences, timeProvider: TimeProvider, pushNotificationManager: PushNotificationManager, isTesting: Bool = false) {
        self.dataManager = dataManager
        self.uiState = uiState
        self.preferences = preferences
        self.timeProvider = timeProvider
        self.pushNotificationManager = pushNotificationManager
    }
    
    deinit {
        stopSyncCheckTimer()
    }

    // MARK: - Compass Check Logic

    var dueDateSoon: [TaskItem] {
        let due = timeProvider.getDate(inDays: 3)
        let open = self.dataManager.items.filter({ $0.isActive }).filter({ $0.dueUntil(date: due) })
        return open.sorted()
    }

    func moveAllPrioritiesToOpen() {
        for p in dataManager.list(which: .priority) {
            dataManager.move(task: p, to: .open)
        }
    }

    func moveStateForward() {
        switch state {
        case .inform:
            if dataManager.list(which: .priority).isEmpty {
                fallthrough
            } else {
                state = .currentPriorities
            }
        case .currentPriorities:
            moveAllPrioritiesToOpen()
            if dataManager.list(which: .pendingResponse).isEmpty {
                fallthrough
            } else {
                state = .pending
            }
        case .pending:
            let dueSoon = dueDateSoon
            if dueSoon.isEmpty {
                fallthrough
            } else {
                state = .dueDate
            }
        case .dueDate:
            for t in dueDateSoon {
                dataManager.move(task: t, to: .priority)
            }
            state = .review
        case .review:
            if os == .iOS {
                endCompassCheck(didFinishCompassCheck: true)
            } else {
                state = .plan
            }
        case .plan:
            endCompassCheck(didFinishCompassCheck: true)
        }
        debugPrint("new state is: \(state)")
    }

    var moveStateForwardText: String {
        if os == .iOS {
            if state == .review {
                return "Finish"
            }
        } else {
            if state == .plan {
                return "Finish"
            }
        }
        return "Next"
    }

    func cancelCompassCheck() {
        uiState.showCompassCheckDialog = false
        state = .inform
        isPaused = false
        pausedState = .inform
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.twoHours))
    }

    func endCompassCheck(didFinishCompassCheck: Bool) {
        uiState.showCompassCheckDialog = false
        state = .inform
        isPaused = false
        pausedState = .inform
        
        // Cancel any pending notifications since CC is done
        timer.cancelTimer()
        stopSyncCheckTimer()
        
        // Cancel push notifications
        Task {
            await pushNotificationManager.cancelCompassCheckNotifications()
        }
        
        debugPrint("endCompassCheck, finished: \(didFinishCompassCheck)")
        debugPrint("did check already today?: \(preferences.didCompassCheckToday)")
        debugPrint("current interval: \(timeProvider.getCompassCheckInterval())")
        debugPrint("next check will be notified at: \(preferences.nextCompassCheckTime)")
        let didCCAlreadyHappenInCurrentInterval = preferences.didCompassCheckToday

        // setting last review date
        if didFinishCompassCheck {
            if !didCCAlreadyHappenInCurrentInterval {
                let secondsOfLastCCBeforeCurrentInterval: TimeInterval = timeProvider.getCompassCheckInterval().start
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
                preferences.lastCompassCheck = timeProvider.now
                debugPrint("lastCompassCheck: \(preferences.lastCompassCheck)")
                debugPrint("next interval: \(preferences.nextCompassCheckTime)")
                debugPrint("did check: \(preferences.didCompassCheckToday)")
            }
        }

        dataManager.updateUndoRedoStatus()
        dataManager.killOldTasks(expireAfter: preferences.expiryAfter, preferences: preferences)
        setupCompassCheckNotification()
    }

    func waitABit() {
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    func pauseCompassCheck() {
        isPaused = true
        pausedState = state
        uiState.showCompassCheckDialog = false
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    func resumeCompassCheck() {
        isPaused = false
        state = pausedState
        uiState.showCompassCheckDialog = true
    }

    var priorityTasks: [TaskItem] {
        return dataManager.list(which: .priority)
    }

    func onPreferencesChange() {
        // If compass check was completed on another device, close the dialog and reset state
        if preferences.didCompassCheckToday {
            if uiState.showCompassCheckDialog {
                logger.info("Compass check completed on another device, closing dialog")
                endCompassCheck(didFinishCompassCheck: false)
            } else if state != .inform {
                // Reset state if not showing dialog but state is not inform
                logger.info("Compass check completed on another device, resetting state")
                state = .inform
                isPaused = false
                pausedState = .inform
                // Reschedule for next interval since CC was completed externally
                setupCompassCheckNotification()
            }
        }
    }
    
    /// Check if compass check was completed on another device and update UI accordingly
    func checkForExternalCompassCheckCompletion() {
        if preferences.didCompassCheckToday && (uiState.showCompassCheckDialog || state != .inform) {
            logger.info("Detected compass check completion on another device during periodic check")
            onPreferencesChange()
        }
    }
    
    /// Start periodic sync check to detect external compass check completion
    private func startSyncCheckTimer() {
        syncCheckTimer?.invalidate()
        syncCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForExternalCompassCheckCompletion()
            }
        }
    }
    
    /// Stop the sync check timer
    private func stopSyncCheckTimer() {
        syncCheckTimer?.invalidate()
        syncCheckTimer = nil
    }

    func startCompassCheckNow() {
        if !uiState.showCompassCheckDialog && state == .inform {
            debugPrint("start compass check \(timeProvider.now)")
            uiState.showCompassCheckDialog = true
        }
    }

    var nextRegularCompassCheckTime: Date {
        var result = self.preferences.compassCheckTime
        if timeProvider.isDate(preferences.lastCompassCheck, inSameDayAs: result) {
            // review happened today, let's do it tomorrow
            result = timeProvider.addADay(result)
        } else {  // today's review missing
            if result < timeProvider.now {
                //regular time passed by, now just do it in 5 minutes to allow app to fully load
                return timeProvider.now.addingTimeInterval(Seconds.oneMin)
            }
        }
        return result
    }

    func onCCNotification() {
        // Check if we're resuming from a paused state first
        if isPaused {
            resumeCompassCheck()
            return
        }
        
        // If compass check dialog is already showing, don't start another one
        if uiState.showCompassCheckDialog {
            return
        }
        
        if uiState.showInfoMessage || uiState.showExportDialog || uiState.showImportDialog || uiState.showSettingsDialog {
            waitABit()
            return
        }
        
        if !self.preferences.didCompassCheckToday {
            self.startCompassCheckNow()
        }
    }
    
    func setupCompassCheckNotification(when: Date? = nil) {
        Task {
            await pushNotificationManager.scheduleSystemPushNotification(timing: preferences.compassCheckTimeComponents, model: self)
            await pushNotificationManager.scheduleStreakReminderNotification(preferences: preferences, timeProvider: timeProvider)
        }

        let time = when ?? nextRegularCompassCheckTime

        uiState.showCompassCheckDialog = false
        
        // Start sync check timer to detect external compass check completion
        startSyncCheckTimer()
        
        // Don't set up timer if CompassCheck already happened in current interval
        guard !preferences.didCompassCheckToday else { return }
        
        // Only set up timer if notifications are authorized
        Task {
            let isAuthorized = await pushNotificationManager.checkNotificationAuthorization()
            if isAuthorized {
                timer.setTimer(forWhen: time) {
                    Task {
                        do {
                            await self.onCCNotification()
                        }
                    }
                }
            }
        }
    }

    func deleteNotifications() {
        timer.cancelTimer()
        stopSyncCheckTimer()
        uiState.showCompassCheckDialog = false
        
        // Cancel push notifications
        Task {
            await pushNotificationManager.cancelCompassCheckNotifications()
        }
    }

    // MARK: - Command Buttons

    /// Compass check button for app commands
    var compassCheckButton: some View {
        Button(action: { self.startCompassCheckNow() }) {
            Label("Compass Check", systemImage: imgCompassCheckStart)
                .foregroundStyle(Color.priority)
                .help("Start compass check")
        }
        .accessibilityIdentifier("compassCheckButton")
    }
}
