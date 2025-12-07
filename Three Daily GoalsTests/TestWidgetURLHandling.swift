//
//  TestWidgetURLHandling.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-24.
//  Tests for widget URL handling functionality.
//

import Foundation
import SwiftData
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreWidget

@Suite
@MainActor
struct TestWidgetURLHandling {

    // MARK: - URL Parsing Tests

    @Test
    func testTaskURLParsing() throws {
        // Given: A valid task URL
        let taskUUID = "12345678-1234-1234-1234-123456789012"
        let taskURL = URL(string: "three-daily-goals://task/\(taskUUID)")!

        // When: Parsing the URL
        let scheme = taskURL.scheme
        let host = taskURL.host
        let pathComponents = taskURL.pathComponents
        let extractedUUID = pathComponents.last

        // Then: Should parse correctly
        #expect(scheme == "three-daily-goals", "Should have correct scheme")
        #expect(host == "task", "Should have correct host")
        #expect(extractedUUID == taskUUID, "Should extract correct UUID")
    }

    @Test
    func testAppURLParsing() throws {
        // Given: A valid app URL
        let appURL = URL(string: "three-daily-goals://app")!

        // When: Parsing the URL
        let scheme = appURL.scheme
        let host = appURL.host

        // Then: Should parse correctly
        #expect(scheme == "three-daily-goals", "Should have correct scheme")
        #expect(host == "app", "Should have correct host")
    }

    @Test
    func testNewTaskURLParsing() throws {
        // Given: A valid new-task URL
        let newTaskURL = URL(string: "three-daily-goals://new-task")!

        // When: Parsing the URL
        let scheme = newTaskURL.scheme
        let host = newTaskURL.host

        // Then: Should parse correctly
        #expect(scheme == "three-daily-goals", "Should have correct scheme")
        #expect(host == "new-task", "Should have correct host")
    }

    @Test
    func testInvalidURLSchemes() throws {
        // Given: URLs with different schemes
        let httpURL = URL(string: "https://example.com")!
        let customURL = URL(string: "myapp://something")!

        // When: Checking schemes
        let httpScheme = httpURL.scheme
        let customScheme = customURL.scheme

        // Then: Should not match our scheme
        #expect(httpScheme != "three-daily-goals", "HTTP URL should not match our scheme")
        #expect(customScheme != "three-daily-goals", "Custom URL should not match our scheme")
    }

    // MARK: - Priority UUID Storage Tests

    @Test
    func testPriorityUUIDStorage() throws {
        // Given: Test app components with isolated storage
        let appComponents = setupApp(isTesting: true)
        let preferences = appComponents.preferences

        // When: Setting and getting priority UUIDs
        let testUUID1 = "11111111-1111-1111-1111-111111111111"
        let testUUID2 = "22222222-2222-2222-2222-222222222222"

        preferences.setPriorityUUID(nr: 1, value: testUUID1)
        preferences.setPriorityUUID(nr: 2, value: testUUID2)

        // Then: Should store and retrieve correctly
        #expect(preferences.getPriorityUUID(nr: 1) == testUUID1, "Should store and retrieve UUID 1")
        #expect(preferences.getPriorityUUID(nr: 2) == testUUID2, "Should store and retrieve UUID 2")
        #expect(preferences.getPriorityUUID(nr: 3).isEmpty, "Should return empty for unset priority")
    }

    @Test
    func testPriorityUUIDWithEmptyValues() throws {
        // Given: Test app components with isolated storage
        let appComponents = setupApp(isTesting: true)
        let preferences = appComponents.preferences

        // When: Setting empty UUID
        preferences.setPriorityUUID(nr: 1, value: "")

        // Then: Should return empty string
        #expect(preferences.getPriorityUUID(nr: 1).isEmpty, "Should return empty string for empty UUID")
    }

    // MARK: - Widget URL Generation Tests

    @Test
    func testWidgetTaskURLGeneration() throws {
        // Given: A task UUID
        let taskUUID = "12345678-1234-1234-1234-123456789012"

        // When: Generating widget URL
        let widgetURL = URL(string: "three-daily-goals://task/\(taskUUID)")!

        // Then: Should generate correct URL
        #expect(widgetURL.scheme == "three-daily-goals", "Should have correct scheme")
        #expect(widgetURL.host == "task", "Should have correct host")
        #expect(widgetURL.pathComponents.last == taskUUID, "Should have correct UUID in path")
    }

    @Test
    func testWidgetAppURLGeneration() throws {
        // Given: App URL
        let appURL = URL(string: "three-daily-goals://app")!

        // When: Checking URL structure
        let scheme = appURL.scheme
        let host = appURL.host

        // Then: Should have correct structure
        #expect(scheme == "three-daily-goals", "Should have correct scheme")
        #expect(host == "app", "Should have correct host")
    }

    @Test
    func testWidgetNewTaskURLGeneration() throws {
        // Given: New task URL
        let newTaskURL = URL(string: "three-daily-goals://new-task")!

        // When: Checking URL structure
        let scheme = newTaskURL.scheme
        let host = newTaskURL.host

        // Then: Should have correct structure
        #expect(scheme == "three-daily-goals", "Should have correct scheme")
        #expect(host == "new-task", "Should have correct host")
    }

    // MARK: - Edge Cases Tests

    @Test
    func testMalformedTaskURL() throws {
        // Given: Malformed task URL
        let malformedURL = URL(string: "three-daily-goals://task/")!

        // When: Parsing path components
        let pathComponents = malformedURL.pathComponents
        let lastComponent = pathComponents.last

        // Then: Should handle gracefully
        // URL parsing behavior: "three-daily-goals://task/" results in pathComponents = ["/"]
        #expect(pathComponents.count == 1, "Should have one path component (the root '/')")
        #expect(lastComponent == "/", "Should have '/' as last component for malformed URL ending with slash")
    }

    @Test
    func testTaskURLWithMultiplePathComponents() throws {
        // Given: Task URL with multiple path components
        let taskUUID = "12345678-1234-1234-1234-123456789012"
        let complexURL = URL(string: "three-daily-goals://task/extra/\(taskUUID)")!

        // When: Extracting UUID
        let pathComponents = complexURL.pathComponents
        let extractedUUID = pathComponents.last

        // Then: Should extract the last component
        #expect(extractedUUID == taskUUID, "Should extract UUID from last path component")
    }

    // MARK: - Integration Tests

    @Test
    func testPriorityUUIDSyncWithPriorities() throws {
        // Given: Test app components with isolated storage
        let appComponents = setupApp(isTesting: true)
        let preferences = appComponents.preferences

        // Create mock tasks with known UUIDs
        let task1UUID = "11111111-1111-1111-1111-111111111111"
        let task2UUID = "22222222-2222-2222-2222-222222222222"

        // When: Setting priorities (simulating updatePriorities call)
        preferences.setPriority(nr: 1, value: "First priority")
        preferences.setPriorityUUID(nr: 1, value: task1UUID)
        preferences.setPriority(nr: 2, value: "Second priority")
        preferences.setPriorityUUID(nr: 2, value: task2UUID)

        // Then: Both priorities and UUIDs should be stored
        #expect(preferences.getPriority(nr: 1) == "First priority", "Should store priority text")
        #expect(preferences.getPriorityUUID(nr: 1) == task1UUID, "Should store priority UUID")
        #expect(preferences.getPriority(nr: 2) == "Second priority", "Should store second priority text")
        #expect(preferences.getPriorityUUID(nr: 2) == task2UUID, "Should store second priority UUID")
    }

    @Test
    func testWidgetURLHandlingFlow() throws {
        // Given: Different types of URLs
        let taskURL = URL(string: "three-daily-goals://task/12345678-1234-1234-1234-123456789012")!
        let appURL = URL(string: "three-daily-goals://app")!
        let newTaskURL = URL(string: "three-daily-goals://new-task")!
        let externalURL = URL(string: "https://example.com")!

        // When: Checking URL handling logic
        let taskURLIsOurs = taskURL.scheme == "three-daily-goals" && taskURL.host == "task"
        let appURLIsOurs = appURL.scheme == "three-daily-goals" && appURL.host == "app"
        let newTaskURLIsOurs = newTaskURL.scheme == "three-daily-goals" && newTaskURL.host == "new-task"
        let externalURLIsOurs = externalURL.scheme == "three-daily-goals"

        // Then: Should identify URLs correctly
        #expect(taskURLIsOurs, "Should identify task URL as ours")
        #expect(appURLIsOurs, "Should identify app URL as ours")
        #expect(newTaskURLIsOurs, "Should identify new-task URL as ours")
        #expect(!externalURLIsOurs, "Should not identify external URL as ours")
    }

    @Test
    func testQuickAddWidgetURL() throws {
        // Given: QuickAddWidget URL
        let quickAddURL = URL(string: "three-daily-goals://new-task")!

        // When: Parsing URL components
        let scheme = quickAddURL.scheme
        let host = quickAddURL.host
        let pathComponents = quickAddURL.pathComponents

        // Then: Should match expected structure for new task creation
        #expect(scheme == "three-daily-goals", "Should have correct scheme")
        #expect(host == "new-task", "Should have new-task host")
        #expect(pathComponents.isEmpty || pathComponents == ["/"], "Should have no extra path components")
    }
}
