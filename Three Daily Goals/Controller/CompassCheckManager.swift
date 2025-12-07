//
//  CompassCheckManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/05/2024.
//

import Foundation
import SwiftUI
import TipKit
import os
import tdgCoreMain

enum CompassCheckState {
    case notStarted
    case inProgress(any CompassCheckStep)
    case finished
    case paused(any CompassCheckStep)
}

@MainActor
@Observable
public final class CompassCheckManager {

    public static let DEFAULT_STEPS: [any CompassCheckStep] = [
        InformStep(),
        CurrentPrioritiesStep(),
        MovePrioritiesToOpenStep(),
        EnergyEffortMatrixStep(),
        PendingResponsesStep(),
        DueDateStep(),
        ReviewStep(),
        MoveToGraveyardStep(),
        EnergyEffortMatrixConsistencyStep(),
        PlanStep(),
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

    // Track when this compass check session started
    private var currentSessionStartTime: Date?

    let timer: CompassCheckTimer = .init()

    // Compass check state
    var state: CompassCheckState = .notStarted

    /// Get the current step from the state
    var currentStep: any CompassCheckStep {
        switch state {
        case .notStarted, .finished:
            return steps.first ?? InformStep()
        case .inProgress(let step), .paused(let step):
            return step
        }
    }

    // Dependencies
    private let dataManager: DataManager
    private let uiState: UIStateManager
    private let preferences: CloudPreferences
    let timeProvider: TimeProvider
    private let pushNotificationManager: PushNotificationManager

    // Step management
    let steps: [any CompassCheckStep]

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
        steps: [any CompassCheckStep] = CompassCheckManager.DEFAULT_STEPS
    ) {
        self.dataManager = dataManager
        self.uiState = uiState
        self.preferences = preferences
        self.timeProvider = timeProvider
        self.pushNotificationManager = pushNotificationManager
        self.steps = steps

        // Initialize state to notStarted - currentStep will be computed from state
    }

    @MainActor
    deinit {
        stopSyncCheckTimer()
    }

    // MARK: - Compass Check Logic

    var dueDateSoon: [TaskItem] {
        let due = timeProvider.getDate(inDays: 3)
        let open = self.dataManager.allTasks.filter({ $0.isActive }).filter({ $0.dueUntil(date: due) })
        return open.sorted()
    }

    func moveAllPrioritiesToOpen() {
        for p in dataManager.list(which: .priority) {
            dataManager.move(task: p, to: .open)
        }
    }

    func moveStateForward() {
        // Execute the current step's action
        executeCurrentStep()

        // Find and move to the next step
        if let nextStep = getNextStep(from: currentStep, os: os) {
            state = .inProgress(nextStep)

            // Process any silent steps that follow
            processSilentSteps()
        } else {
            // No more steps, finish the compass check
            endCompassCheck(didFinishCompassCheck: true)
        }
    }

    var moveStateForwardText: String {
        return getButtonText(for: currentStep, os: os)
    }

    /// Check if the compass check is finished
    var isFinished: Bool {
        if case .finished = state {
            return true
        }
        return false
    }

    /// Get the current step's view
    @ViewBuilder
    func getCurrentStepView() -> some View {
        currentStep.view(compassCheckManager: self)
    }

    func cancelCompassCheck() {
        uiState.showCompassCheckDialog = false
        state = .paused(currentStep)
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.twoHours))
    }

    func endCompassCheck(didFinishCompassCheck: Bool) {
        uiState.showCompassCheckDialog = false
        state = .finished

        // Clear session start time
        currentSessionStartTime = nil

        // Cancel any pending notifications since CC is done
        timer.cancelTimer()
        stopSyncCheckTimer()

        // Cancel push notifications
        Task {
            await pushNotificationManager.cancelCompassCheckNotifications()
        }

        let didCCAlreadyHappenInCurrentInterval = preferences.didCompassCheckToday

        // setting last review date
        if didFinishCompassCheck {
            if !didCCAlreadyHappenInCurrentInterval {
                let secondsOfLastCCBeforeCurrentInterval: TimeInterval = timeProvider.getCompassCheckInterval().start
                    .timeIntervalSince(preferences.lastCompassCheck)
                if !(0...Seconds.fullDay).contains(secondsOfLastCCBeforeCurrentInterval) {
                    // reset the streak to 0
                    preferences.daysOfCompassCheck = 0  // will soon be set to 1
                }
                preferences.daysOfCompassCheck = preferences.daysOfCompassCheck + 1
                if preferences.daysOfCompassCheck > preferences.longestStreak {
                    preferences.longestStreak = preferences.daysOfCompassCheck
                }
                preferences.lastCompassCheck = timeProvider.now
            }
        }

        dataManager.updateUndoRedoStatus()
        setupCompassCheckNotification()

        // The @Observable mechanism in CloudPreferences will automatically trigger UI updates
        // when the stored properties change, so no manual UI refresh is needed
    }

    func waitABit() {
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.fiveMin))
    }

    func pauseCompassCheck() {
        state = .paused(currentStep)
        uiState.showCompassCheckDialog = false
        setupCompassCheckNotification(when: timeProvider.now.addingTimeInterval(Seconds.fiveMin))
    }

    func resumeCompassCheck() {
        // Resume from paused state
        if case .paused(let step) = state {
            state = .inProgress(step)
        }
        uiState.showCompassCheckDialog = true
    }

    var priorityTasks: [TaskItem] {
        return dataManager.list(which: .priority)
    }

    func onPreferencesChange() {
        // If compass check was completed on another device, close the dialog and reset state
        // Only close if lastCompassCheck was updated AFTER this session started
        if preferences.didCompassCheckToday {
            // Check if lastCompassCheck was updated after this session started
            let wasCompletedDuringThisSession: Bool
            if let sessionStart = currentSessionStartTime {
                wasCompletedDuringThisSession = preferences.lastCompassCheck > sessionStart
            } else {
                // No session start time means we're not in an active session
                wasCompletedDuringThisSession = false
            }

            // Only act if the check was completed externally (not during this session)
            if wasCompletedDuringThisSession {
                if uiState.showCompassCheckDialog {
                    logger.info("Compass check completed on another device, closing dialog")
                    endCompassCheck(didFinishCompassCheck: false)
                } else {
                    switch state {
                    case .inProgress, .paused:
                        // Reset state if not showing dialog but state is not the first step
                        logger.info("Compass check completed on another device, resetting state")
                        state = .finished
                        // Reschedule for next interval since CC was completed externally
                        setupCompassCheckNotification()
                    default:
                        break
                    }
                }
            }
        }
    }

    /// Check if compass check was completed on another device and update UI accordingly
    func checkForExternalCompassCheckCompletion() {
        if preferences.didCompassCheckToday {
            let shouldCheck =
                uiState.showCompassCheckDialog
                || {
                    switch state {
                    case .inProgress, .paused:
                        return true
                    default:
                        return false
                    }
                }()

            if shouldCheck {
                logger.info("Detected compass check completion on another device during periodic check")
                onPreferencesChange()
            }
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
        if !uiState.showCompassCheckDialog {
            switch state {
            case .notStarted, .finished:
                // Record when this session started
                currentSessionStartTime = timeProvider.now
                state = .inProgress(currentStep)
                uiState.showCompassCheckDialog = true
            default:
                break
            }
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
        if case .paused = state {
            resumeCompassCheck()
            return
        }

        // If compass check dialog is already showing, don't start another one
        if uiState.showCompassCheckDialog {
            return
        }

        if uiState.showInfoMessage || uiState.showExportDialog || uiState.showImportDialog || uiState.showSettingsDialog
        {
            waitABit()
            return
        }

        if !self.preferences.didCompassCheckToday {
            self.startCompassCheckNow()
        }
    }

    func setupCompassCheckNotification(when: Date? = nil) {
        Task {
            await pushNotificationManager.scheduleSystemPushNotification(model: self)
            await pushNotificationManager.scheduleStreakReminderNotification()
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
            Label("Compass Check", systemImage: imgCompassCheck)
                .foregroundStyle(Color.priority)
                .help("Start compass check")
        }
        .accessibilityIdentifier("compassCheckButton")
        .popoverTip(CompassCheckTip())
    }

    // MARK: - Step Management Methods

    /// Get the next step in the flow, skipping steps that should be skipped
    private func getNextStep(from currentStep: any CompassCheckStep, os: SupportedOS) -> (any CompassCheckStep)? {
        let currentIndex = steps.firstIndex { $0.id == currentStep.id } ?? 0

        // Look for the next step that should not be skipped
        for i in (currentIndex + 1)..<steps.count {
            let step = steps[i]

            // Check if step should be skipped (includes user toggles and platform-specific logic)
            if !shouldSkipStep(step) {
                return step
            }
        }

        // If no next step found, we're at the end
        return nil
    }

    /// Get the button text for the current step
    private func getButtonText(for currentStep: any CompassCheckStep, os: SupportedOS) -> String {
        let nextVisibleStep = getNextVisibleStep(from: currentStep, os: os)

        // If this is the last visible step, show "Finish"
        if nextVisibleStep == nil {
            return "Finish"
        }

        // For all other cases, show "Next"
        return "Next"
    }

    /// Check if the current step should be skipped
    private func shouldSkipStep(_ step: any CompassCheckStep) -> Bool {
        // First check if the user has disabled this step
        if !isStepEnabled(step) {
            return true
        }

        // Then check if the step is applicable
        return !step.isApplicable(dataManager: dataManager, timeProvider: timeProvider)
    }

    /// Check if a step is enabled by the user
    private func isStepEnabled(_ step: any CompassCheckStep) -> Bool {
        return preferences.isCompassCheckStepEnabled(stepId: step.id)
    }

    // MARK: - State Machine Helper Methods

    /// Execute the current step's action
    private func executeCurrentStep() {
        currentStep.act(dataManager: dataManager, timeProvider: timeProvider, preferences: preferences)
    }

    /// Process any silent steps that follow the current step
    private func processSilentSteps() {
        while currentStep.isSilent {
            executeCurrentStep()

            // Find the next step after this silent one
            guard let nextStep = getNextStep(from: currentStep, os: os) else {
                // No more steps, finish the compass check
                endCompassCheck(didFinishCompassCheck: true)
                break
            }
            state = .inProgress(nextStep)
        }
    }

    /// Get the next visible (non-silent) step for button text logic
    private func getNextVisibleStep(from currentStep: any CompassCheckStep, os: SupportedOS) -> (any CompassCheckStep)?
    {
        let currentIndex = steps.firstIndex { $0.id == currentStep.id } ?? 0

        // Look for the next step that should not be skipped and is not silent
        for i in (currentIndex + 1)..<steps.count {
            let step = steps[i]

            // Check if step should be skipped (includes user toggles and platform-specific logic)
            if !shouldSkipStep(step) {
                // If this step is silent, continue looking for the next visible step
                guard step.isSilent else {
                    return step
                }
                // Recursively find the next visible step after this silent one
                return getNextVisibleStep(from: step, os: os)
            }
        }

        // If no next visible step found, we're at the end
        return nil
    }
}
