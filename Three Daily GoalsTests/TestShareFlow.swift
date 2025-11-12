//
//  TestShareFlow.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-15.
//  Simplified after creating dedicated AttachmentResolver tests.
//

import Foundation
import Testing
import UniformTypeIdentifiers
import tdgCoreTest

@testable import Three_Daily_Goals
@testable import macosShare

@Suite
@MainActor
struct TestShareFlow {

    // MARK: - High-Level ShareFlow Orchestration Tests

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
        if case .attachment(let url, let type, _) = payload {
            #expect(type == .plainText, "Should infer correct UTType")
            #expect(FileManager.default.fileExists(atPath: url.path), "Should create valid file")
        } else {
            #expect(Bool(false), "Expected attachment payload, got: \(String(describing: payload))")
        }

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Business Logic Tests (ShareFlow-specific behavior)

    @Test
    func testFileURLBecomesAttachment() async throws {
        // CRITICAL: File URLs from Finder should become attachments, not web URLs
        // Regression test for bug where file:// URLs were treated as web URLs

        // Given: A file URL (as shared from Finder)
        let fileURL = URL(fileURLWithPath: "/Users/test/invoice.pdf")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockFileURL = fileURL  // Finder provides files as fileURL, not URL
        mockProvider.registeredTypeIdentifiers = [UTType.fileURL.identifier]

        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should be attachment, NOT url
        #expect(payload != nil, "Should resolve file URL")
        if case .attachment(let url, _, let suggestedFilename) = payload {
            #expect(
                url.lastPathComponent.contains("invoice") || url.lastPathComponent.contains("pdf"),
                "Should preserve filename information")
            #expect(suggestedFilename == "invoice.pdf", "Should preserve original filename")
        } else {
            #expect(Bool(false), "File URL should become attachment, not URL. Got: \(String(describing: payload))")
        }
    }

    @Test
    func testFileURLViaURLTypeBecomesAttachment() async throws {
        // CRITICAL: File URLs provided as UTType.url should ALSO become attachments
        // Regression test for bug where file:// URLs in mockURL were skipped and lost

        // Given: A file URL provided via UTType.url (this is how Finder sometimes provides files)
        let fileURL = URL(fileURLWithPath: "/Users/test/Package.swift")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = fileURL  // File URL coming through URL type identifier
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]

        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should be attachment with original filename, NOT lost
        #expect(payload != nil, "Should resolve file URL")
        if case .attachment(let url, _, let suggestedFilename) = payload {
            #expect(url.path.contains("Package.swift"), "Should preserve file path")
            #expect(suggestedFilename == "Package.swift", "Should extract and preserve original filename")
        } else {
            #expect(Bool(false), "File URL via mockURL should become attachment. Got: \(String(describing: payload))")
        }
    }

    @Test
    func testWebURLStaysURL() async throws {
        // Web URLs (https://) should remain as URL type, not become attachments

        // Given: A web URL
        let webURL = URL(string: "https://example.com")!
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = webURL
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]

        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should be URL type, not attachment
        #expect(payload != nil, "Should resolve web URL")
        if case .url(let urlString) = payload {
            #expect(urlString == "https://example.com", "Should preserve URL string")
        } else {
            #expect(Bool(false), "Web URL should stay as URL type, not attachment. Got: \(String(describing: payload))")
        }
    }

    @Test
    func testHTTPURLStaysURL() async throws {
        // HTTP URLs (not just HTTPS) should also remain as URL type

        // Given: An HTTP URL
        let httpURL = URL(string: "http://example.com")!
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = httpURL
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]

        // When: Resolving the payload
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should be URL type
        if case .url(let urlString) = payload {
            #expect(urlString == "http://example.com", "Should preserve HTTP URL")
        } else {
            #expect(Bool(false), "HTTP URL should stay as URL type. Got: \(String(describing: payload))")
        }
    }

    @Test
    func testHTMLDetectionAndConversion() async throws {
        // Test ShareFlow's HTML detection and conversion to attachment
        let htmlContent = "<!DOCTYPE html><html><head><title>Test</title></head><body>Hello</body></html>"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = htmlContent
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving HTML content
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should convert HTML to attachment
        #expect(payload != nil, "Should resolve HTML as attachment")
        if case .attachment(let url, let type, _) = payload {
            #expect(type == .html, "Should detect as HTML type")
            #expect(url.pathExtension == "html", "Should have .html extension")
        } else {
            #expect(Bool(false), "Expected attachment payload for HTML, got: \(String(describing: payload))")
        }
    }

    @Test
    func testResolutionPriorityOrder() async throws {
        // Test ShareFlow's priority ordering: URL > Text > Attachment
        let tempURL = createTempFile(content: "Test content", fileExtension: "txt")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = URL(string: "https://example.com")!
        mockProvider.mockText = "Test text"
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [
            UTType.url.identifier,
            UTType.plainText.identifier,
            UTType.fileURL.identifier,
        ]

        // When: Resolving with multiple types available
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should prioritize URL (highest priority)
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
    func testNoSupportedTypes() async throws {
        // Test ShareFlow behavior with unsupported types
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = ["com.unknown.type"]

        // When: Resolving with no supported types
        let payload = try await ShareFlow.resolve(from: mockProvider)

        // Then: Should return nil
        #expect(payload == nil, "Should return nil for unsupported types")
    }

    @Test
    func testHTMLDetectionEdgeCases() async throws {
        // Test ShareFlow's HTML detection with various edge cases
        let testCases = [
            ("<!DOCTYPE html><html><body>Test</body></html>", true),
            ("This is plain text", false),
            ("Some text with < but not HTML", false),
            ("<HTML><BODY>Test</BODY></HTML>", true),  // uppercase
            ("  <!doctype html>  ", true),  // with whitespace
        ]

        for (content, shouldBeHTML) in testCases {
            let mockProvider = MockNSItemProvider()
            mockProvider.mockText = content
            mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

            let payload = try await ShareFlow.resolve(from: mockProvider)

            #expect(payload != nil, "Should resolve content: \(content)")
            if shouldBeHTML {
                if case .attachment(let url, let type, _) = payload {
                    #expect(type == .html, "Should detect as HTML: \(content)")
                    #expect(url.pathExtension == "html", "Should have .html extension")
                } else {
                    #expect(Bool(false), "Expected attachment for HTML content: \(content)")
                }
            } else {
                if case .text(let text) = payload {
                    #expect(text == content, "Should preserve text content: \(content)")
                } else {
                    #expect(Bool(false), "Expected text payload for: \(content)")
                }
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
