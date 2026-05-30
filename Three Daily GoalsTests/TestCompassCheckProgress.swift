//
//  TestCompassCheckProgress.swift
//  Three Daily GoalsTests
//
//  Covers visibleSteps/currentVisibleIndex used to drive the dialog progress bar.
//

import Foundation
import SwiftUI
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestCompassCheckProgress {

    private func createDataLoader() -> TestDataLoader {
        return { _ in
            let priority = TaskItem(title: "P")
            priority.state = .priority
            let open = TaskItem(title: "O")
            open.state = .open
            return [priority, open]
        }
    }

    @Test
    func visibleStepsExcludesSilentSteps() throws {
        let steps: [any CompassCheckStep] = [InformStep(), ReviewStep()]
        let app = setupApp(isTesting: true, loaderForTests: createDataLoader(), compassCheckSteps: steps)
        let manager = app.compassCheckManager

        let visible = manager.visibleSteps
        let nonSilentCount = steps.filter { !$0.isSilent }.count
        #expect(visible.count == nonSilentCount)
        #expect(visible.allSatisfy { !$0.isSilent })
    }

    @Test
    func visibleStepsExcludesUserDisabledSteps() throws {
        // `pending` is a non-silent step — disabling it should drop a segment.
        let steps: [any CompassCheckStep] = [InformStep(), PendingResponsesStep(), ReviewStep()]
        let app = setupApp(isTesting: true, loaderForTests: createDataLoader(), compassCheckSteps: steps)
        let manager = app.compassCheckManager

        // Make sure the step is enabled at the start (defaults vary across runs).
        app.preferences.setCompassCheckStepEnabled(stepId: "pending", enabled: true)
        let baseline = manager.visibleSteps.count
        #expect(manager.visibleSteps.contains { $0.id == "pending" })

        app.preferences.setCompassCheckStepEnabled(stepId: "pending", enabled: false)

        #expect(manager.visibleSteps.count == baseline - 1)
        #expect(manager.visibleSteps.contains { $0.id == "pending" } == false)
    }

    @Test
    func currentVisibleIndexIsZeroWhenNotStarted() throws {
        let steps: [any CompassCheckStep] = [InformStep(), ReviewStep()]
        let app = setupApp(isTesting: true, loaderForTests: createDataLoader(), compassCheckSteps: steps)
        let manager = app.compassCheckManager

        #expect(manager.currentVisibleIndex == 0)
    }

    @Test
    func currentVisibleIndexAdvancesWithMoveForward() throws {
        let steps: [any CompassCheckStep] = [InformStep(), ReviewStep()]
        let app = setupApp(isTesting: true, loaderForTests: createDataLoader(), compassCheckSteps: steps)
        let manager = app.compassCheckManager

        let total = manager.visibleSteps.count
        #expect(total >= 2)

        // First step
        #expect(manager.currentVisibleIndex == 0)

        // Walk forward and verify index increments while in-progress.
        manager.moveStateForward()
        if case .inProgress = manager.state {
            #expect(manager.currentVisibleIndex == 1)
        }

        // After completing the last step the manager goes to .finished — index clamps to last segment.
        if !manager.isFinished {
            manager.moveStateForward()
        }
        #expect(manager.currentVisibleIndex >= 0)
        #expect(manager.currentVisibleIndex <= total - 1)
    }
}
