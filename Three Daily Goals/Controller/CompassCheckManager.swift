//
//  CompassCheckManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/05/2024.
//

import Foundation
import SwiftUI
import os


@MainActor
@Observable
final class CompassCheckManager {
    
    public static let DEFAULT_STEPS: [any CompassCheckStep] = [
        InformStep(),
        CurrentPrioritiesStep(),
        PendingResponsesStep(),
        DueDateStep(),
        ReviewStep(),
        PlanStep()
    ]
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

    var currentStep: any CompassCheckStep
    
    // Pause functionality
    var isPaused: Bool = false
    var pausedStep: any CompassCheckStep

    // Dependencies
    private let dataManager: DataManager
    private let uiState: UIStateManager
    private let preferences: CloudPreferences
    let timeProvider: TimeProvider
    private let pushNotificationManager: PushNotificationManager
    
    // Step management
    private let steps: [any CompassCheckStep]

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

    init(
        dataManager: DataManager,
        uiState: UIStateManager,
        preferences: CloudPreferences,
        timeProvider: TimeProvider,
        pushNotificationManager: PushNotificationManager,
        customSteps: [any CompassCheckStep] = CompassCheckManager.DEFAULT_STEPS
    ) {
        self.dataManager = dataManager
        self.uiState = uiState
        self.preferences = preferences
        self.timeProvider = timeProvider
        self.pushNotificationManager = pushNotificationManager
        self.steps = customSteps
        
        // Initialize currentStep and pausedStep to the first step
        var currentStep = self.steps.first!
        self.currentStep = currentStep
        self.pausedStep = currentStep
    }
    
    @MainActor
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
        let nextStep = moveToNextStep(from: currentStep, os: os)
        
        if nextStep == nil {
            // We're at the end, finish the compass check
            endCompassCheck(didFinishCompassCheck: true)
        } else {
            currentStep = nextStep!
        }
        
        debugPrint("new step is: \(type(of: currentStep))")
    }

    var moveStateForwardText: String {
        return getButtonText(for: currentStep, os: os)
    }
    
    /// Get the current step's view
    @ViewBuilder
    func getCurrentStepView() -> some View {
        currentStep.view(compassCheckManager: self)
    }

    func cancelCompassCheck() {
        uiState.showCompassCheckDialog = false
        currentStep = steps.first ?? InformStep()
        isPaused = false
        pausedStep = currentStep
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.twoHours))
    }

    func endCompassCheck(didFinishCompassCheck: Bool) {
        uiState.showCompassCheckDialog = false
        currentStep = steps.first ?? InformStep()
        isPaused = false
        pausedStep = currentStep
        
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
        
        // The @Observable mechanism in CloudPreferences will automatically trigger UI updates
        // when the stored properties change, so no manual UI refresh is needed
    }

    func waitABit() {
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    func pauseCompassCheck() {
        isPaused = true
        pausedStep = currentStep
        uiState.showCompassCheckDialog = false
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.fiveMin))
    }
    
    func resumeCompassCheck() {
        isPaused = false
        currentStep = pausedStep
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
            } else if currentStep.id != steps.first?.id {
                // Reset state if not showing dialog but state is not the first step
                logger.info("Compass check completed on another device, resetting state")
                currentStep = steps.first ?? InformStep()
                isPaused = false
                pausedStep = currentStep
                // Reschedule for next interval since CC was completed externally
                setupCompassCheckNotification()
            }
        }
    }
    
    /// Check if compass check was completed on another device and update UI accordingly
    func checkForExternalCompassCheckCompletion() {
        if preferences.didCompassCheckToday && (uiState.showCompassCheckDialog || currentStep.id != steps.first?.id) {
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
        if !uiState.showCompassCheckDialog && currentStep.id == steps.first?.id {
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
    
    // MARK: - Step Management Methods
    
    /// Get the next step in the flow, skipping steps that should be skipped
    private func getNextStep(from currentStep: any CompassCheckStep, os: SupportedOS) -> (any CompassCheckStep)? {
        let currentIndex = steps.firstIndex { $0.id == currentStep.id } ?? 0
        
        // Look for the next step that should not be skipped
        for i in (currentIndex + 1)..<steps.count {
            let step = steps[i]
            
            // Check if step should be skipped (includes platform-specific logic)
            if !step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider) {
                return step
            }
        }
        
        // If no next step found, we're at the end
        return nil
    }
    
    /// Execute the current step's onMoveToNext action and return the next step
    private func moveToNextStep(from currentStep: any CompassCheckStep, os: SupportedOS) -> (any CompassCheckStep)? {
        // Execute the current step's action
        currentStep.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        
        // Find the next step
        return getNextStep(from: currentStep, os: os)
    }
    
    /// Get the button text for the current step
    private func getButtonText(for currentStep: any CompassCheckStep, os: SupportedOS) -> String {
        let nextStep = getNextStep(from: currentStep, os: os)
        
        // If this is the last step, show "Finish"
        if nextStep == nil {
            return "Finish"
        }
        
        // For all other cases, show "Next"
        return "Next"
    }
    
    /// Check if the current step should be skipped
    private func shouldSkipStep(_ step: any CompassCheckStep) -> Bool {
        return step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider)
    }
}
