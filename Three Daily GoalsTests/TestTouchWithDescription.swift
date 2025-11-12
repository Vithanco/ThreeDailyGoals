//
//  TestTouchWithDescription.swift
//  Three Daily GoalsTests
//
//  Created by Assistant on 31/08/2025.
//

import Foundation
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestTouchWithDescription {

    var appComps: AppComponents!
    var dataManager: DataManager!

    init() {
        appComps = setupApp(isTesting: true)
        dataManager = appComps.dataManager
    }

    @Test
    func testTouchWithDescriptionAddsComment() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)

        // Verify initial state
        #expect(task.comments?.count ?? 0 == 0, "Initial comment count should be 0")

        // Test touch with description
        let description = "Completed the first phase"
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: description)

        // Verify comment was added
        #expect(task.comments?.count ?? 0 == 1, "Comment count should be 1 after adding comment")
        #expect(task.comments?.first?.text == description, "Comment text should match the description")

        // Verify changed date was updated
        #expect(task.changed > task.created, "Changed date should be greater than created date")
    }

    @Test
    func testTouchWithEmptyDescriptionUsesDefaultTouch() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)

        // Verify initial state
        #expect(task.comments?.count ?? 0 == 0, "Initial comment count should be 0")

        // Test touch with empty description
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "")

        // Verify default touch comment was added
        #expect(task.comments?.count ?? 0 == 1, "Comment count should be 1 after adding comment")
        #expect(
            task.comments?.first?.text == "You 'touched' this task.", "Comment text should be default touch message")

        // Verify changed date was updated
        #expect(task.changed > task.created, "Changed date should be greater than created date")
    }

    @Test
    func testTouchWithWhitespaceOnlyDescriptionUsesDefaultTouch() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)

        // Verify initial state
        #expect(task.comments?.count ?? 0 == 0, "Initial comment count should be 0")

        // Test touch with whitespace-only description
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "   \n\t  ")

        // Verify default touch comment was added
        #expect(task.comments?.count ?? 0 == 1, "Comment count should be 1 after adding comment")
        #expect(
            task.comments?.first?.text == "You 'touched' this task.", "Comment text should be default touch message")

        // Verify changed date was updated
        #expect(task.changed > task.created, "Changed date should be greater than created date")
    }
}
