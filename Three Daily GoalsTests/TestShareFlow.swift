//
//  TestShareFlow.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-15.
//

import Foundation
import Testing
import UniformTypeIdentifiers
@testable import Three_Daily_Goals
@testable import macosShare

@Suite
@MainActor
struct TestShareFlow {
    
    // MARK: - Test SharePayload Resolution
    
    @Test
    func testResolveURLPayload() async throws {
        // Given: A mock item provider that provides a URL
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = URL(string: "https://example.com")!
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]
        
        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)
        
        // Then: Should return URL payload
        #expect(payload != nil, "Should resolve URL payload")
        if case .url(let urlString) = payload {
            #expect(urlString == "https://example.com", "Should return correct URL string")
        } else {
            #expect(Bool(false), "Expected URL payload, got: \(String(describing: payload))")
        }
    }
    
    @Test
    func testResolveTextPayload() async throws {
        // Given: A mock item provider that provides text
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = "This is test text"
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
        
        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)
        
        // Then: Should return text payload
        #expect(payload != nil, "Should resolve text payload")
        if case .text(let text) = payload {
            #expect(text == "This is test text", "Should return correct text")
        } else {
            #expect(Bool(false), "Expected text payload, got: \(String(describing: payload))")
        }
    }
    
    @Test
    func testResolveAttachmentPayload() async throws {
        // Given: A mock item provider that provides a file attachment
        let tempURL = createTempFile(content: "Test file content", fileExtension: "txt")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [UTType.fileURL.identifier]
        
        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)
        
        // Then: Should return attachment payload
        #expect(payload != nil, "Should resolve attachment payload")
        if case .attachment(let url, let type) = payload {
            #expect(url.lastPathComponent == tempURL.lastPathComponent, "Should return correct file URL")
            #expect(type == .plainText, "Should infer correct UTType")
        } else {
            #expect(Bool(false), "Expected attachment payload, got: \(String(describing: payload))")
        }
        
        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }
    
    @Test
    func testResolveHTMLAsAttachment() async throws {
        // Given: A mock item provider that provides HTML text
        let htmlContent = "<!DOCTYPE html><html><head><title>Test</title></head><body>Hello</body></html>"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = htmlContent
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
        
        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)
        
        // Then: Should return attachment payload (HTML converted to file)
        #expect(payload != nil, "Should resolve HTML as attachment")
        if case .attachment(let url, let type) = payload {
            #expect(type == .html, "Should return HTML type")
            #expect(url.pathExtension == "html", "Should have .html extension")
            
            // Verify file content
            let fileContent = try String(contentsOf: url)
            #expect(fileContent == htmlContent, "Should preserve HTML content")
        } else {
            #expect(Bool(false), "Expected attachment payload for HTML, got: \(String(describing: payload))")
        }
    }
    
    @Test
    func testResolvePriorityOrder() async throws {
        // Given: A mock item provider that provides multiple types (URL, text, attachment)
        let tempURL = createTempFile(content: "Test content", fileExtension: "txt")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = URL(string: "https://example.com")!
        mockProvider.mockText = "Test text"
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [
            UTType.url.identifier,
            UTType.plainText.identifier,
            UTType.fileURL.identifier
        ]
        
        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)
        
        // Then: Should prioritize URL over text and attachment
        #expect(payload != nil, "Should resolve payload")
        if case .url(let urlString) = payload {
            #expect(urlString == "https://example.com", "Should prioritize URL")
        } else {
            #expect(Bool(false), "Expected URL payload (highest priority), got: \(String(describing: payload))")
        }
        
        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }
    
    @Test
    func testResolveNoPayload() async throws {
        // Given: A mock item provider that provides no supported types
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = ["com.unknown.type"]
        
        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)
        
        // Then: Should return nil
        #expect(payload == nil, "Should return nil for unsupported types")
    }
    
    @Test
    func testLooksLikeHTML() async throws {
        // Test various HTML-like strings
        let htmlCases = [
            "<!DOCTYPE html><html><body>Test</body></html>",
            "<html><head><title>Test</title></head><body>Content</body></html>",
            "  <!doctype html>  ", // with whitespace
            "<HTML><BODY>Test</BODY></HTML>", // uppercase
            "Some text <head> and <body> tags"
        ]
        
        for htmlContent in htmlCases {
            let mockProvider = MockNSItemProvider()
            mockProvider.mockText = htmlContent
            mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
            
            let payload = try await ShareFlow.resolve(from: mockProvider)
            
            #expect(payload != nil, "Should resolve HTML content")
            if case .attachment(let url, let type) = payload {
                #expect(type == .html, "Should detect as HTML type")
                #expect(url.pathExtension == "html", "Should have .html extension")
            } else {
                #expect(Bool(false), "Expected attachment payload for HTML content: \(htmlContent)")
            }
        }
    }
    
    @Test
    func testDoesNotLookLikeHTML() async throws {
        // Test non-HTML strings that should remain as text
        let textCases = [
            "This is plain text",
            "Some text with < but not HTML",
            "Email: user@example.com",
            "Just a regular sentence."
        ]
        
        for textContent in textCases {
            let mockProvider = MockNSItemProvider()
            mockProvider.mockText = textContent
            mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]
            
            let payload = try await ShareFlow.resolve(from: mockProvider)
            
            #expect(payload != nil, "Should resolve text content")
            if case .text(let text) = payload {
                #expect(text == textContent, "Should preserve original text")
            } else {
                #expect(Bool(false), "Expected text payload for: \(textContent)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTempFile(content: String, fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            #expect(Bool(false), "Failed to create temp file: \(error)")
            return fileURL
        }
    }
}

// MARK: - Mock NSItemProvider

final class MockNSItemProvider: NSItemProvider, @unchecked Sendable {
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
    
    override func loadItem(
        forTypeIdentifier typeIdentifier: String,
        options: [AnyHashable : Any]? = nil,
        completionHandler: NSItemProvider.CompletionHandler?
    ) {
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
    
    func loadFileRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (URL?, Error?) -> Void) {
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
            
            if let result = result {
                completionHandler(result, nil)
            } else {
                completionHandler(nil, NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported type"]))
            }
        }
    }
}
