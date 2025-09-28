//
//  InformStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import tdgCoreMain

public struct InformStep: CompassCheckStep {
    public let id: String = "inform"
    public let name: String = "Welcome & Information"
    public let isSilent: Bool = false
    
    public func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Inform step is always available - it's the starting point
        return true
    }
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckInformView())
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // No specific actions needed for inform step
    }
    
    public func shouldSkip(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        return !isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider)
    }
}
