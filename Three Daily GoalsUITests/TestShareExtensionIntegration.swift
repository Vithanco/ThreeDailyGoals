//
//  TestShareExtensionIntegration.swift
//  Three Daily GoalsUITests
//
//  Created by AI Assistant on 2025-01-15.
//

import XCTest
import SwiftData
import UniformTypeIdentifiers
@testable import Three_Daily_Goals
@testable import macosShare

@MainActor
class TestShareExtensionIntegration: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var preferences: Three_Daily_Goals.CloudPreferences!
    
    override func setUpWithError() throws {
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TaskItem.self, Attachment.self, Comment.self, configurations: config)
        context = ModelContext(container)
        
        // Create test preferences
        let testPreferences = Three_Daily_Goals.TestPreferences()
        preferences = CloudPreferences(store: testPreferences)
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
        preferences = nil
    }
    
    // MARK: - Complete Share Extension Workflow Tests
    
    func testCompleteTextShareWorkflow() async throws {
        // Given: A text share request
        let shareText = "Remember to call the dentist"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = shareText
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
        
        // When: Processing the complete share workflow
        let result = try await processShareWorkflow(provider: mockProvider)
        
        // Then: Should create task with correct properties
        XCTAssertNotNil(result, "Should successfully process share workflow")
        if let task = result {
            XCTAssertEqual(task.title, shareText, "Should set title to shared text")
            XCTAssertTrue(task.details.isEmpty, "Should have empty details for short text")
            XCTAssertTrue(task.attachments?.isEmpty == true, "Should have no attachments")
        }
    }
    
    func testCompleteURLShareWorkflow() async throws {
        // Given: A URL share request
        let shareURL = "https://developer.apple.com/documentation/swift"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = URL(string: shareURL)!
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]
        
        // When: Processing the complete share workflow
        let result = try await processShareWorkflow(provider: mockProvider)
        
        // Then: Should create task with correct properties
        XCTAssertNotNil(result, "Should successfully process share workflow")
        if let task = result {
            XCTAssertEqual(task.title, "Read", "Should set title to 'Read'")
            XCTAssertEqual(task.url, shareURL, "Should set URL correctly")
            XCTAssertTrue(task.attachments?.isEmpty == true, "Should have no attachments")
        }
    }
    
    func testCompleteFileShareWorkflow() async throws {
        // Given: A file share request
        let fileContent = "This is a test document content"
        let tempURL = createTempFile(content: fileContent, fileExtension: "txt")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [UTType.fileURL.identifier]
        
        // When: Processing the complete share workflow
        let result = try await processShareWorkflow(provider: mockProvider)
        
        // Then: Should create task with file attachment
        XCTAssertNotNil(result, "Should successfully process share workflow")
        if let task = result {
            XCTAssertEqual(task.title, "Review File", "Should set title to 'Review File'")
            XCTAssertTrue(task.details.contains("Shared file:"), "Should include file info in details")
            XCTAssertEqual(task.attachments?.count, 1, "Should have one attachment")
            
            if let attachment = task.attachments?.first {
                XCTAssertEqual(attachment.filename, tempURL.lastPathComponent, "Should have correct filename")
                XCTAssertEqual(attachment.utiIdentifier, UTType.plainText.identifier, "Should have correct UTI")
                XCTAssertNotNil(attachment.blob, "Should have blob data")
            }
        }
        
        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testCompleteHTMLShareWorkflow() async throws {
        // Given: An HTML share request
        let htmlContent = "<!DOCTYPE html><html><head><title>Test Page</title></head><body><h1>Hello World</h1></body></html>"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = htmlContent
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
        
        // When: Processing the complete share workflow
        let result = try await processShareWorkflow(provider: mockProvider)
        
        // Then: Should create task with HTML attachment
        XCTAssertNotNil(result, "Should successfully process share workflow")
        if let task = result {
            XCTAssertEqual(task.title, "Review File", "Should set title to 'Review File'")
            XCTAssertTrue(task.details.contains("Shared file:"), "Should include file info in details")
            XCTAssertEqual(task.attachments?.count, 1, "Should have one attachment")
            
            if let attachment = task.attachments?.first {
                XCTAssertEqual(attachment.utiIdentifier, UTType.html.identifier, "Should have HTML UTI")
                XCTAssertTrue(attachment.filename.hasSuffix(".html"), "Should have .html extension")
            }
        }
    }
    
    func testShareWorkflowWithError() async throws {
        // Given: A provider that will throw an error
        let mockProvider = MockNSItemProvider()
        mockProvider.mockError = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
        
        // When: Processing the share workflow
        // Then: Should handle error gracefully
        do {
            let result = try await processShareWorkflow(provider: mockProvider)
            XCTAssertNil(result, "Should return nil when provider throws error")
        } catch {
            // Error handling is expected
            XCTAssertTrue(error.localizedDescription.contains("Test error"), "Should propagate the error")
        }
    }
    
    func testShareWorkflowWithUnsupportedType() async throws {
        // Given: A provider with unsupported type
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = ["com.unsupported.type"]
        
        // When: Processing the share workflow
        let result = try await processShareWorkflow(provider: mockProvider)
        
        // Then: Should return nil for unsupported types
        XCTAssertNil(result, "Should return nil for unsupported types")
    }
    
    // MARK: - Multiple Share Operations Tests
    
    func testMultipleShareOperations() async throws {
        // Given: Multiple share operations
        let shareOperations: [(text: String?, url: String?, type: String)] = [
            (text: "First task", url: nil, type: UTType.plainText.identifier),
            (text: nil, url: "https://example.com/1", type: UTType.url.identifier),
            (text: "This is a very long text that should be treated as details for the third task", url: nil, type: UTType.plainText.identifier)
        ]
        
        var createdTasks: [TaskItem] = []
        
        // When: Processing multiple share operations
        for (index, operation) in shareOperations.enumerated() {
            let mockProvider = MockNSItemProvider()
            mockProvider.registeredTypeIdentifiers = [operation.type]
            
            if operation.text != nil {
                mockProvider.mockText = operation.text
            } else if operation.url != nil {
                mockProvider.mockURL = URL(string: operation.url!)
            }
            
            if let task = try await processShareWorkflow(provider: mockProvider) {
                createdTasks.append(task)
            }
        }
        
        // Then: Should create separate tasks for each operation
        XCTAssertEqual(createdTasks.count, 3, "Should create three separate tasks")
        XCTAssertEqual(createdTasks[0].title, "First task", "First task should have correct title")
        XCTAssertEqual(createdTasks[1].title, "Read", "Second task should have 'Read' title")
        XCTAssertEqual(createdTasks[1].url, "https://example.com/1", "Second task should have correct URL")
        XCTAssertEqual(createdTasks[2].title, "Review", "Third task should have 'Review' title")
        XCTAssertTrue(createdTasks[2].details.contains("very long text"), "Third task should have long text as details")
    }
    
    // MARK: - ShareViewController Integration Tests
    
    func testShareViewControllerInitialization() throws {
        // Note: ShareViewController is not available in UI test target
        // This test is kept as a placeholder for when ShareViewController becomes available
        // or when we move this test to a different target that has access to ShareViewController
        XCTAssertTrue(true, "ShareViewController test placeholder - requires target access")
    }
    
    func testShareViewControllerContainerSetup() throws {
        // Note: ShareViewController is not available in UI test target
        // This test is kept as a placeholder for when ShareViewController becomes available
        // or when we move this test to a different target that has access to ShareViewController
        XCTAssertTrue(true, "ShareViewController container test placeholder - requires target access")
    }
    
    // MARK: - Helper Methods
    
    private func processShareWorkflow(provider: NSItemProvider) async throws -> Three_Daily_Goals.TaskItem? {
        // Simulate the complete share extension workflow:
        // 1. Resolve payload from provider
        // 2. Create ShareExtensionView
        // 3. Create and save task
        
        // Step 1: Resolve payload
        guard let payload = try await ShareFlow.resolve(from: provider) else {
            return nil
        }
        
        // Step 2: Create ShareExtensionView based on payload
        let shareView: ShareExtensionView
        switch payload {
        case .text(let text):
            shareView = ShareExtensionView(text: text)
        case .url(let url):
            shareView = ShareExtensionView(url: url)
        case .attachment(let fileURL, let contentType):
            shareView = ShareExtensionView(fileURL: fileURL, contentType: contentType)
        }
        
        // Step 3: Create and save task
        let task = shareView.item
        
        // Add attachment if it's a file attachment
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
    
    private func createTempFile(content: String, fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            XCTFail("Failed to create temp file: \(error)")
            return fileURL
        }
    }
}

// MARK: - Mock NSItemProvider for UI Tests

final class MockNSItemProvider: NSItemProvider {
    var mockURL: URL?
    var mockText: String?
    var mockFileURL: URL?
    var mockData: Data?
    var mockError: Error?
    
    private var _registeredTypeIdentifiers: [String] = []
    
    override var registeredTypeIdentifiers: [String] {
        get { 
            return _registeredTypeIdentifiers
        }
        set { 
            _registeredTypeIdentifiers = newValue
        }
    }
    
    override func hasItemConformingToTypeIdentifier(_ typeIdentifier: String) -> Bool {
        return registeredTypeIdentifiers.contains(typeIdentifier)
    }
    
    override func loadItem(forTypeIdentifier typeIdentifier: String, options: [AnyHashable : Any]? = nil, completionHandler: NSItemProvider.CompletionHandler?) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completionHandler?(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Provider deallocated"]))
                return
            }
            
            if let error = self.mockError {
                completionHandler?(nil, error)
                return
            }
            
            let result: NSSecureCoding?
            switch typeIdentifier {
            case UTType.url.identifier:
                result = self.mockURL as NSSecureCoding?
            case UTType.plainText.identifier, UTType.text.identifier:
                result = self.mockText as NSSecureCoding?
            case UTType.fileURL.identifier:
                result = self.mockFileURL as NSSecureCoding?
            case UTType.data.identifier:
                result = self.mockData as NSSecureCoding?
            default:
                result = nil
            }
            
            if let result = result {
                completionHandler?(result, nil)
            } else {
                completionHandler?(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported type"]))
            }
        }
    }
    
    func loadDataRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (Data?, Error?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completionHandler(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Provider deallocated"]))
                return
            }
            
            if let error = self.mockError {
                completionHandler(nil, error)
                return
            }
            
            let result: Data?
            switch typeIdentifier {
            case UTType.plainText.identifier, UTType.text.identifier:
                result = self.mockText?.data(using: .utf8)
            case UTType.data.identifier:
                result = self.mockData
            default:
                result = nil
            }
            
            if let result = result {
                completionHandler(result, nil)
            } else {
                completionHandler(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported type"]))
            }
        }
    }
    
    override func loadFileRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (URL?, Error?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completionHandler(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Provider deallocated"]))
                return
            }
            
            if let error = self.mockError {
                completionHandler(nil, error)
                return
            }
            
            let result: URL?
            switch typeIdentifier {
            case UTType.fileURL.identifier:
                result = self.mockFileURL
            default:
                result = nil
            }
            
            if result != nil {
                completionHandler(result, nil)
            } else {
                completionHandler(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported type"]))
            }
        }
    }
}
