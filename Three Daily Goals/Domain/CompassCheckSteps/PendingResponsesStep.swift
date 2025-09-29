//
//  PendingResponsesStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import tdgCoreMain

public struct PendingResponsesStep: CompassCheckStep {
    public let id: String = "pending"
    public let name: String = "Pending Responses"
    public let description: String = "Review and close tasks that are waiting for responses from others."
    public let isSilent: Bool = false
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckPendingResponses())
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // No specific actions needed - user can close tasks in the view
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are pending response tasks
        return !dataManager.list(which: .pendingResponse).isEmpty
    }
}
