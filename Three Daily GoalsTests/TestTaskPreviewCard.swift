//
//  TestTaskPreviewCard.swift
//  Three Daily GoalsTests
//

import Foundation
import SwiftUI
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestTaskPreviewCard {

    @Test
    func testInitialisesForOpenTaskWithoutMetadata() throws {
        let appComps = setupApp(isTesting: true, loaderForTests: { _ in [] })
        let task = TaskItem(title: "Reply to Simon", state: .open)
        appComps.dataManager.addItem(item: task)

        let card = TaskPreviewCard(item: task)
            .environment(appComps.dataManager)
            .environment(appComps.preferences)

        #expect(card != nil)
    }

    @Test
    func testInitialisesForFullyDressedPriorityTask() throws {
        let appComps = setupApp(isTesting: true, loaderForTests: { _ in [] })
        let task = TaskItem(
            title: "Quarterly review doc",
            details: "Include Q2 metrics and the roadmap slide.",
            state: .priority
        )
        task.due = Date.now.addingTimeInterval(3 * 24 * 60 * 60)
        appComps.dataManager.addItem(item: task)
        task.updateTags(["work", "writing", "high-energy", "big-task"], createComments: false)
        task.addComment(text: "Added energy/effort: Deep Work")
        task.addComment(text: "Set due date Fri")

        let card = TaskPreviewCard(item: task)
            .environment(appComps.dataManager)
            .environment(appComps.preferences)

        #expect(card != nil)
        #expect(task.tags.contains("work"))
        #expect(EnergyEffortQuadrant.from(task: task) == .highEnergyBigTask)
    }

    @Test
    func testFiltersEnergyEffortTagsFromVisibleTags() throws {
        let task = TaskItem(title: "Refactor data layer")
        task.allTagsString = "work,tech-debt,low-energy,big-task"

        let visible = TaskPreviewCard.visibleTags(for: task)

        #expect(visible == ["work", "tech-debt"])
    }

    @Test
    func testRecentActivityReturnsMostRecentCommentsFirst() throws {
        let appComps = setupApp(isTesting: true, loaderForTests: { _ in [] })
        let task = TaskItem(title: "Fix login bug")
        appComps.dataManager.addItem(item: task)

        let first = task.addComment(text: "Added task").comments!.last!
        let second = task.addComment(text: "Maria added trace logs").comments!.last!
        // Push the second comment's date forward so order is unambiguous.
        first.created = Date.now.addingTimeInterval(-7200)
        second.created = Date.now.addingTimeInterval(-3600)

        let activity = TaskPreviewCard.recentActivity(for: task, limit: 3)

        #expect(activity.count == 2)
        #expect(activity.first?.text == "Maria added trace logs")
    }

    @Test
    func testRecentActivityIsCappedByLimit() throws {
        let appComps = setupApp(isTesting: true, loaderForTests: { _ in [] })
        let task = TaskItem(title: "Update app icon")
        appComps.dataManager.addItem(item: task)

        for i in 0..<5 {
            task.addComment(text: "entry \(i)")
        }

        let activity = TaskPreviewCard.recentActivity(for: task, limit: 3)

        #expect(activity.count == 3)
    }
}
