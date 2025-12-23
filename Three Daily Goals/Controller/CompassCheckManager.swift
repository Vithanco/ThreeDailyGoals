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

enum CompassCheckState: CustomStringConvertible {
    case notStarted
    case inProgress(any CompassCheckStep)
    case finished
    case paused(any CompassCheckStep)

    nonisolated var description: String {
        switch self {
        case .notStarted:
            return "notStarted"
        case .inProgress:
            return "inProgress"
        case .finished:
            return "finished"
        case .paused:
            return "paused"
        }
    }
}

@MainActor
@Observable
public final class CompassCheckManager {

    public static let DEFAULT_STEPS: [any CompassCheckStep] = [
        InformStep(),
        EnergyEffortMatrixConsistencyStep(),
        CurrentPrioritiesStep(),
        MovePrioritiesToOpenStep(),
        EnergyEffortMatrixStep(),
        PendingResponsesStep(),
        DueDateStep(),
        ReviewStep(),
        MoveToGraveyardStep(),
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

        // Load saved state if available and still valid
        loadSavedState()
    }

    @MainActor
    deinit {
        stopSyncCheckTimer()
    }

    // MARK: - State Persistence

    /// Load saved compass check state from preferences
    private func loadSavedState() {
        // Check if we have a saved step
        guard let savedStepId = preferences.currentCompassCheckStepId,
            let savedPeriodStart = preferences.currentCompassCheckPeriodStart
        else {
            // No saved state, start fresh
            state = .notStarted
            return
        }

        // Check if we're still in the same review period
        let currentInterval = timeProvider.getCompassCheckInterval()
        if !currentInterval.contains(savedPeriodStart) {
            // Different review period, reset to start
            logger.info(
                "Compass check period changed since last save, resetting to start (saved: \(savedPeriodStart), current: \(currentInterval.start))"
            )
            preferences.clearCompassCheckProgress()
            state = .notStarted
            return
        }

        // Find the saved step in our steps array
        if let step = steps.first(where: { $0.id == savedStepId }) {
            logger.info("Resuming compass check from saved step: \(savedStepId)")
            state = .paused(step)
        } else {
            logger.warning("Saved step ID '\(savedStepId)' not found in steps, resetting")
            preferences.clearCompassCheckProgress()
            state = .notStarted
        }
    }

    /// Save current compass check progress to preferences
    private func saveCurrentProgress() {
        let currentInterval = timeProvider.getCompassCheckInterval()

        switch state {
        case .inProgress(let step), .paused(let step):
            preferences.currentCompassCheckStepId = step.id
            preferences.currentCompassCheckPeriodStart = currentInterval.start
            logger.info("Saved compass check progress: step=\(step.id), period=\(currentInterval.start)")
        case .notStarted, .finished:
            // Clear saved state when not in progress
            preferences.clearCompassCheckProgress()
            logger.info("Cleared compass check progress (state: \(self.state))")
        }
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
        // Check if another device has progressed further - sync to their step
        if let remoteStepId = preferences.currentCompassCheckStepId,
           isStepAhead(remoteStepId, of: currentStep.id) {
            logger.info("Remote device is ahead at step '\(remoteStepId)', syncing...")
            if let remoteStep = steps.first(where: { $0.id == remoteStepId }) {
                state = .inProgress(remoteStep)
                // Don't save - we're syncing TO remote, not FROM local
                processSilentSteps()
                return
            }
        }

        // Execute the current step's action
        executeCurrentStep()

        // Find and move to the next step
        if let nextStep = getNextStep(from: currentStep, os: os) {
            state = .inProgress(nextStep)

            // Save progress after moving to next step
            saveCurrentProgress()

            // Process any silent steps that follow
            processSilentSteps()
        } else {
            // No more steps, finish the compass check
            endCompassCheck(didFinishCompassCheck: true)
        }
    }

    /// Go back to the previous visible step (skipping silent steps)
    func goBackOneStep() {
        guard canGoBack else { return }

        if let previousStep = getPreviousVisibleStep(from: currentStep) {
            state = .inProgress(previousStep)
            saveCurrentProgress()
            logger.info("Went back to step: \(previousStep.id)")
        }
    }

    /// Whether we can go back (not on first visible step)
    var canGoBack: Bool {
        return getPreviousVisibleStep(from: currentStep) != nil
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
        // Just close the dialog - state is already saved
        uiState.showCompassCheckDialog = false
        // Don't change state - keep it as is (will be .paused from saveCurrentProgress or already paused)
        // Restart timer for regular time
        setupCompassCheckNotification()
    }

    func endCompassCheck(didFinishCompassCheck: Bool) {
        uiState.showCompassCheckDialog = false
        state = .finished

        // Clear saved progress
        preferences.clearCompassCheckProgress()

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
        // Sync step across devices instead of closing dialog

        // Check if the saved step changed externally
        guard let savedStepId = preferences.currentCompassCheckStepId else {
            // No saved step - compass check was completed or cancelled externally
            if preferences.didCompassCheckToday {
                // Completed on another device
                switch state {
                case .inProgress, .paused:
                    if uiState.showCompassCheckDialog {
                        logger.info("Compass check completed on another device, closing dialog")
                        endCompassCheck(didFinishCompassCheck: false)
                    } else {
                        logger.info("Compass check completed on another device, resetting state")
                        state = .finished
                        setupCompassCheckNotification()
                    }
                default:
                    break
                }
            }
            return
        }

        // We have a saved step - sync to it if different from current
        switch state {
        case .inProgress(let currentStep), .paused(let currentStep):
            if currentStep.id != savedStepId {
                // Step changed externally, sync to the new step
                if let newStep = steps.first(where: { $0.id == savedStepId }) {
                    logger.info("Step changed on another device from '\(currentStep.id)' to '\(savedStepId)', syncing...")
                    state = .inProgress(newStep)
                    // Don't close dialog - just update to show the new step
                } else {
                    logger.warning("External step ID '\(savedStepId)' not found in steps")
                }
            }
        case .notStarted, .finished:
            // If we're not in progress but there's a saved step, we should resume
            if let step = steps.first(where: { $0.id == savedStepId }) {
                logger.info("Compass check started on another device at step '\(savedStepId)', syncing...")
                state = .paused(step)
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
                // Start fresh compass check from first step
                let firstStep = steps.first ?? InformStep()
                state = .inProgress(firstStep)
                saveCurrentProgress()
                uiState.showCompassCheckDialog = true
            case .paused:
                // Resume from saved state
                state = .inProgress(currentStep)
                uiState.showCompassCheckDialog = true
            case .inProgress:
                // Already in progress, just show dialog
                uiState.showCompassCheckDialog = true
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

        // Don't interrupt other dialogs - they will naturally close and CC can be started manually
        if uiState.showInfoMessage || uiState.showExportDialog || uiState.showImportDialog || uiState.showSettingsDialog
        {
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

    /// Get the index of a step by its ID
    func stepIndex(of stepId: String) -> Int? {
        return steps.firstIndex { $0.id == stepId }
    }

    /// Check if a step (by ID) is ahead of another step (by ID)
    private func isStepAhead(_ stepId: String, of otherStepId: String) -> Bool {
        guard let stepIdx = stepIndex(of: stepId),
              let otherIdx = stepIndex(of: otherStepId) else {
            return false
        }
        return stepIdx > otherIdx
    }

    /// Get the previous visible (non-silent) step, skipping silent and disabled steps
    private func getPreviousVisibleStep(from currentStep: any CompassCheckStep) -> (any CompassCheckStep)? {
        guard let currentIndex = steps.firstIndex(where: { $0.id == currentStep.id }), currentIndex > 0 else {
            return nil
        }

        // Look backwards for the previous step that should not be skipped and is not silent
        for i in stride(from: currentIndex - 1, through: 0, by: -1) {
            let step = steps[i]

            // Check if step should be skipped (includes user toggles and platform-specific logic)
            if !shouldSkipStep(step) && !step.isSilent {
                return step
            }
        }

        return nil
    }

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
            saveCurrentProgress()
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
