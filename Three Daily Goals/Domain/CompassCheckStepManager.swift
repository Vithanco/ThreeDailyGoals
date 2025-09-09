//
//  CompassCheckStepManager.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI



/// Manages the flow of Compass Check steps
@MainActor
class CompassCheckStepManager {
    
    public static let DEFAULT_STEPS : [CompassCheckStep] = [
        InformStep(),
        CurrentPrioritiesStep(),
        PendingResponsesStep(),
        DueDateStep(),
        ReviewStep(),
        PlanStep()
    ]
    private let steps: [CompassCheckStep]
    private let dataManager: DataManager
    private let timeProvider: TimeProvider
    
    init(dataManager: DataManager, timeProvider: TimeProvider, steps: [CompassCheckStep] = DEFAULT_STEPS) {
        self.dataManager = dataManager
        self.timeProvider = timeProvider
        self.steps = steps
    }
    
    /// Get the current step based on the state
    func getCurrentStep(for state: CompassCheckState) -> CompassCheckStep? {
        return steps.first { $0.state == state }
    }
    
    /// Get the next step in the flow, skipping steps that should be skipped
    func getNextStep(from currentState: CompassCheckState, os: SupportedOS) -> CompassCheckState {
        let currentIndex = steps.firstIndex { $0.state == currentState } ?? 0
        
        // Look for the next step that should not be skipped
        for i in (currentIndex + 1)..<steps.count {
            let step = steps[i]
            
            // On iOS, skip the plan step entirely
            if os == .iOS && step.state == .plan {
                continue
            }
            
            if !step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider) {
                return step.state
            }
        }
        
        // If no next step found, we're at the end
        return currentState
    }
    
    /// Execute the current step's onMoveToNext action and return the next state
    func moveToNextStep(from currentState: CompassCheckState, os: SupportedOS) -> CompassCheckState {
        guard let currentStep = getCurrentStep(for: currentState) else {
            return currentState
        }
        
        // Execute the current step's action
        currentStep.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        
        // Find the next step
        return getNextStep(from: currentState, os: os)
    }
    
    /// Get the button text for the current step
    func getButtonText(for state: CompassCheckState, os: SupportedOS) -> String {
        let nextState = getNextStep(from: state, os: os)
        
        // If this is the last step, show "Finish"
        if nextState == state {
            return "Finish"
        }
        
        // For all other cases, show "Next"
        return "Next"
    }
    
    /// Check if the current step should be skipped
    func shouldSkipStep(_ state: CompassCheckState) -> Bool {
        guard let step = getCurrentStep(for: state) else {
            return true
        }
        return step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider)
    }
}
