//
//  TestShareExtensionHarness.swift
//  Three Daily GoalsUITests
//
//  Created by AI Assistant on 2025-01-15.
//

import XCTest
import SwiftData
import UniformTypeIdentifiers
@testable import Three_Daily_Goals
@testable import tdgCoreMain
@testable import tdgCoreShare
import tdgCoreTest

/// Comprehensive test harness demonstrating how to test share extensions
/// This file shows how to use the test utilities and covers edge cases
@MainActor
class TestShareExtensionHarness: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var preferences: CloudPreferences!
    
    override func setUpWithError() throws {
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TaskItem.self, Attachment.self, Comment.self, configurations: config)
        context = ModelContext(container)
        
        // Create test preferences
        let testPreferences = TestPreferences()
        preferences = CloudPreferences(store: testPreferences, timeProvider: RealTimeProvider())
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
        preferences = nil
    }
    
    // MARK: - Test Harness Demonstration
    
    func testShareExtensionHarnessWithUtilities() async throws {
        // This test demonstrates how to use the test harness utilities
        
        // Given: Various share scenarios
        let scenarios: [ShareTestScenario] = [
            .shortText,
            .longText,
            .url,
            .htmlText,
            .fileAttachment(.plainText),
            .fileAttachment(.html),
            .fileAttachment(.json)
        ]
        
        var createdTasks: [TaskItem] = []
        var tempFiles: [URL] = []
        
        // When: Processing each scenario
        for scenario in scenarios {
            let provider = ShareExtensionTestUtilities.createTestScenario(scenario)
            
            // Extract temp files for cleanup
            if case .fileAttachment = scenario {
                if let fileURL = provider.mockFileURL {
                    tempFiles.append(fileURL)
                }
            }
            
            if let task = try await processShareWorkflow(provider: provider) {
                createdTasks.append(task)
            }
        }
        
        // Then: Verify all scenarios were processed correctly
        XCTAssertEqual(createdTasks.count, scenarios.count, "Should create tasks for all scenarios")
        
        // Verify specific scenarios
        ShareExtensionTestUtilities.assertTaskCreated(
            createdTasks[0],
            expectedTitle: "Short task",
            expectedAttachmentCount: 0
        )
        
        ShareExtensionTestUtilities.assertTaskCreated(
            createdTasks[1],
            expectedTitle: "Review",
            expectedDetails: "This is a very long text that exceeds thirty characters and should be treated as details for the task",
            expectedAttachmentCount: 0
        )
        
        ShareExtensionTestUtilities.assertTaskCreated(
            createdTasks[2],
            expectedTitle: "Read",
            expectedURL: "https://example.com/article",
            expectedAttachmentCount: 0
        )
        
        ShareExtensionTestUtilities.assertTaskCreated(
            createdTasks[3],
            expectedTitle: "Review File",
            expectedAttachmentCount: 1
        )
        
        // Verify file attachments
        for i in 4..<createdTasks.count {
            let task = createdTasks[i]
            XCTAssertEqual(task.title, "Review File", "File attachment tasks should have 'Review File' title")
            XCTAssertEqual(task.attachments?.count, 1, "File attachment tasks should have one attachment")
        }
        
        // Cleanup
        ShareExtensionTestUtilities.cleanupTempFiles(tempFiles)
    }
    
    func testShareExtensionErrorHandling() async throws {
        // Given: Error scenarios
        let errorScenarios: [ShareTestScenario] = [
            .error(NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])),
            .unsupportedType
        ]
        
        // When: Processing error scenarios
        for scenario in errorScenarios {
            let provider = ShareExtensionTestUtilities.createTestScenario(scenario)
            let result = try await processShareWorkflow(provider: provider)
            
            // Then: Should handle errors gracefully
            XCTAssertNil(result, "Should return nil for error scenarios: \(scenario.description)")
        }
    }
    
    func testShareExtensionWithCustomData() async throws {
        // Given: Custom data scenarios
        let customData = "Custom test data".data(using: .utf8)!
        let provider = ShareExtensionTestUtilities.createMockProvider(
            data: customData,
            typeIdentifiers: [UTType.data.identifier]
        )
        
        // When: Processing custom data
        let result = try await processShareWorkflow(provider: provider)
        
        // Then: Should handle custom data
        XCTAssertNotNil(result, "Should handle custom data")
        if let task = result {
            XCTAssertEqual(task.title, "Review File", "Should create file attachment task")
            XCTAssertEqual(task.attachments?.count, 1, "Should have one attachment")
        }
    }
    
    func testShareExtensionPerformance() async throws {
        // Given: Multiple share operations for performance testing
        let operationCount = 50
        var providers: [tdgCoreTest.MockNSItemProvider] = []
        
        for i in 0..<operationCount {
            let provider = ShareExtensionTestUtilities.createMockProvider(
                text: "Performance test task \(i)",
                typeIdentifiers: [UTType.plainText.identifier]
            )
            providers.append(provider)
        }
        
        // When: Processing multiple operations
        let startTime = Date()
        var createdTasks: [TaskItem] = []
        
        for provider in providers {
            if let task = try await processShareWorkflow(provider: provider) {
                createdTasks.append(task)
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then: Should complete within reasonable time
        XCTAssertEqual(createdTasks.count, operationCount, "Should create all tasks")
        XCTAssertLessThan(duration, 5.0, "Should complete within 5 seconds (actual: \(duration)s)")
    }
    
    func testShareExtensionMemoryUsage() async throws {
        // Given: Large file attachment
        let largeContent = String(repeating: "Large file content. ", count: 1000)
        let tempURL = ShareExtensionTestUtilities.createTempFile(content: largeContent, fileExtension: "txt")
        
        let provider = ShareExtensionTestUtilities.createMockProvider(
            fileURL: tempURL,
            typeIdentifiers: [UTType.fileURL.identifier]
        )
        
        // When: Processing large file
        let result = try await processShareWorkflow(provider: provider)
        
        // Then: Should handle large files
        XCTAssertNotNil(result, "Should handle large files")
        if let task = result {
            XCTAssertEqual(task.attachments?.count, 1, "Should have one attachment")
            if let attachment = task.attachments?.first {
                XCTAssertGreaterThan(attachment.byteSize, 0, "Should have non-zero byte size")
            }
        }
        
        // Cleanup
        ShareExtensionTestUtilities.cleanupTempFile(tempURL)
    }
    
    // MARK: - Helper Methods
    
    private func processShareWorkflow(provider: NSItemProvider) async throws -> TaskItem? {
        // Simulate the complete share extension workflow
        guard let payload = try await ShareFlow.resolve(from: provider) else {
            return nil
        }
        
        let shareView: ShareExtensionView
        switch payload {
        case .text(let text):
            shareView = ShareExtensionView(text: text)
        case .url(let url):
            shareView = ShareExtensionView(url: url)
        case .attachment(let fileURL, let contentType):
            shareView = ShareExtensionView(fileURL: fileURL, contentType: contentType)
        }
        
        let task = shareView.item
        
        if shareView.isFileAttachment,
           let fileURL = shareView.originalFileURL,
           let contentType = shareView.originalContentType {
            _ = try addAttachment(
                fileURL: fileURL,
                type: contentType,
                to: task,
                sortIndex: 0,
                in: context
            )
        }
        
        context.insert(task)
        try context.save()
        
        return task
    }
}
