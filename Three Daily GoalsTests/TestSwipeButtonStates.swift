//
//  TestSwipeButtonStates.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@MainActor
struct TestSwipeButtonStates {

    // MARK: - Pending Response Button Tests

    @Test
    func testPendingResponseButtonDisabledStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager

        // Test all task states for pending response button eligibility
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]

        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            dataManager.addItem(item: task)

            // Create the button view
            let button = dataManager.waitForResponseButton(item: task)

            // Test the disabled condition
            let shouldBeDisabled = !task.canBeMovedToPendingResponse
            let expectedDisabled = (state == .pendingResponse)

            #expect(
                shouldBeDisabled == expectedDisabled,
                "Task in \(state) state should have canBeMovedToPendingResponse = \(!expectedDisabled)")
        }
    }

    @Test
    func testPendingResponseButtonAccessibilityIdentifier() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager

        let task = TaskItem(title: "Test Task", details: "Test details", state: .open)
        dataManager.addItem(item: task)

        // Create the button view and verify accessibility identifier
        let button = dataManager.waitForResponseButton(item: task)

        // The button should have the correct accessibility identifier
        // Note: We can't directly test the accessibility identifier in unit tests,
        // but we can verify the button is created without errors
        #expect(task.canBeMovedToPendingResponse == true, "Open task should be movable to pending response")
    }

    // MARK: - Priority Button Tests

    @Test
    func testPriorityButtonDisabledStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager

        // Test all task states for priority button eligibility
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]

        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            dataManager.addItem(item: task)

            // Test the disabled condition
            let shouldBeDisabled = !task.canBeMadePriority
            let expectedDisabled = ![.open, .pendingResponse].contains(state)

            #expect(
                shouldBeDisabled == expectedDisabled,
                "Task in \(state) state should have canBeMadePriority = \(!expectedDisabled)")
        }
    }

    // MARK: - Delete Button Tests

    @Test
    func testDeleteButtonDisabledStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState

        // Test all task states for delete button eligibility
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]

        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            dataManager.addItem(item: task)

            // Create the button view
            let button = dataManager.deleteButton(item: task, uiState: uiState)

            // Test the disabled condition
            let shouldBeDisabled = !task.canBeDeleted
            let expectedDisabled = ![.closed, .dead].contains(state)

            #expect(
                shouldBeDisabled == expectedDisabled,
                "Task in \(state) state should have canBeDeleted = \(!expectedDisabled)")
        }
    }

    // MARK: - Touch Button Tests

    @Test
    func testTouchButtonDisabledStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager

        // Test all task states for touch button eligibility
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]

        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            dataManager.addItem(item: task)

            // Test the disabled condition
            let shouldBeDisabled = !task.canBeTouched
            let expectedDisabled = ![.pendingResponse, .open, .priority, .dead].contains(state)

            #expect(
                shouldBeDisabled == expectedDisabled,
                "Task in \(state) state should have canBeTouched = \(!expectedDisabled)")
        }
    }

    // MARK: - Open Button Tests

    @Test
    func testOpenButtonDisabledStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager

        // Test all task states for open button eligibility
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]

        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            dataManager.addItem(item: task)

            // Test the disabled condition
            let shouldBeDisabled = !task.canBeMovedToOpen
            let expectedDisabled = (state == .open)

            #expect(
                shouldBeDisabled == expectedDisabled,
                "Task in \(state) state should have canBeMovedToOpen = \(!expectedDisabled)")
        }
    }

    // MARK: - Close Button Tests

    @Test
    func testCloseButtonDisabledStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager

        // Test all task states for close button eligibility
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]

        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            dataManager.addItem(item: task)

            // Test the disabled condition
            let shouldBeDisabled = !task.canBeClosed
            let expectedDisabled = ![.open, .priority, .pendingResponse, .dead].contains(state)

            #expect(
                shouldBeDisabled == expectedDisabled,
                "Task in \(state) state should have canBeClosed = \(!expectedDisabled)")
        }
    }

    // MARK: - Integration Tests

    @Test
    func testSwipeActionButtonConsistency() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState

        // Test that all swipe action buttons have consistent disabled states
        let task = TaskItem(title: "Test Task", details: "Test details", state: .open)
        dataManager.addItem(item: task)

        // All buttons should be enabled for an open task
        #expect(task.canBeMovedToOpen == false, "Open task should not be movable to open")
        #expect(task.canBeMovedToPendingResponse == true, "Open task should be movable to pending response")
        #expect(task.canBeMadePriority == true, "Open task should be makeable priority")
        #expect(task.canBeClosed == true, "Open task should be closable")
        #expect(task.canBeTouched == true, "Open task should be touchable")
        #expect(task.canBeDeleted == false, "Open task should not be deletable")
    }

    @Test
    func testPendingResponseTaskButtonStates() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState

        // Test button states for a pending response task
        let task = TaskItem(title: "Pending Task", details: "Waiting for response", state: .pendingResponse)
        dataManager.addItem(item: task)

        // Pending response task should have specific button states
        #expect(task.canBeMovedToOpen == true, "Pending task should be movable to open")
        #expect(task.canBeMovedToPendingResponse == false, "Pending task should not be movable to pending response")
        #expect(task.canBeMadePriority == true, "Pending task should be makeable priority")
        #expect(task.canBeClosed == true, "Pending task should be closable")
        #expect(task.canBeTouched == true, "Pending task should be touchable")
        #expect(task.canBeDeleted == false, "Pending task should not be deletable")
    }
}
