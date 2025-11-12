//
//  TestAttachmentResolver.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 23/08/2025.
//

import Foundation
import UniformTypeIdentifiers
import XCTest
import tdgCoreTest

@testable import tdgCoreShare

final class TestAttachmentResolver: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    // MARK: - URL Resolution Tests

    func testResolveURLSuccess() async throws {
        // Given: A mock provider that offers a URL
        let testURL = URL(string: "https://example.com")!
        let mockProvider = MockNSItemProvider()
        mockProvider.mockURL = testURL
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]

        // When: Resolving URL
        let result = try await AttachmentResolver.resolveURL(from: mockProvider)

        // Then: Should return the URL
        XCTAssertEqual(result, testURL)
    }

    func testResolveURLFailure() async throws {
        // Given: A mock provider that doesn't offer URL
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving URL
        let result = try await AttachmentResolver.resolveURL(from: mockProvider)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    func testResolveURLError() async throws {
        // Given: A mock provider that throws an error
        let mockProvider = MockNSItemProvider()
        mockProvider.mockError = NSError(domain: "TestError", code: 1, userInfo: nil)
        mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]

        // When/Then: Should throw the error
        do {
            _ = try await AttachmentResolver.resolveURL(from: mockProvider)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
        }
    }

    // MARK: - Text Resolution Tests

    func testResolveTextPlainText() async throws {
        // Given: A mock provider with plain text
        let testText = "Hello, World!"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = testText
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return the text
        XCTAssertEqual(result, testText)
    }

    func testResolveTextUTF8PlainText() async throws {
        // Given: A mock provider with UTF-8 plain text
        let testText = "Hello, 世界!"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = testText
        mockProvider.registeredTypeIdentifiers = ["public.utf8-plain-text"]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return the text
        XCTAssertEqual(result, testText)
    }

    func testResolveTextWithDataRepresentation() async throws {
        // Given: A mock provider that provides text as data
        let testText = "Data representation text"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = testText
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return the text
        XCTAssertEqual(result, testText)
    }

    func testResolveTextWithURL() async throws {
        // Given: A mock provider that provides text via URL
        let testText = "URL text content"
        let tempURL = createTempFile(content: testText, fileExtension: "txt")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = testText
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return the text
        XCTAssertEqual(result, testText)

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    func testResolveTextWithData() async throws {
        // Given: A mock provider that provides text as Data object
        let testText = "Data object text"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = testText
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return the text
        XCTAssertEqual(result, testText)
    }

    func testResolveTextPriority() async throws {
        // Given: A mock provider with multiple text types
        let testText = "Priority test"
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = testText
        mockProvider.registeredTypeIdentifiers = [
            UTType.text.identifier,
            UTType.plainText.identifier,
            "public.utf8-plain-text",
        ]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return the text (preference order should be handled)
        XCTAssertEqual(result, testText)
    }

    func testResolveTextFailure() async throws {
        // Given: A mock provider with no text types
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = [UTType.image.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    // MARK: - Attachment Resolution Tests

    func testResolveAttachmentWithFileURL() async throws {
        // Given: A mock provider with file URL
        let tempURL = createTempFile(content: "Test file", fileExtension: "txt")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [UTType.fileURL.identifier]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should return attachment resolution
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.url.lastPathComponent, tempURL.lastPathComponent)
        XCTAssertEqual(result?.type, .plainText)

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    func testResolveAttachmentWithImage() async throws {
        // Given: A mock provider with image file
        let tempURL = createTempFile(content: "fake image data", fileExtension: "png")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [UTType.image.identifier]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should return attachment resolution
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .png)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result!.url.path))

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    func testResolveAttachmentWithPDF() async throws {
        // Given: A mock provider with PDF file
        let tempURL = createTempFile(content: "fake PDF data", fileExtension: "pdf")
        let mockProvider = MockNSItemProvider()
        mockProvider.mockFileURL = tempURL
        mockProvider.registeredTypeIdentifiers = [UTType.pdf.identifier]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should return attachment resolution
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .pdf)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result!.url.path))

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    func testResolveAttachmentWithData() async throws {
        // Given: A mock provider with data
        let testData = "Test data content".data(using: .utf8)!
        let mockProvider = MockNSItemProvider()
        mockProvider.mockData = testData
        mockProvider.registeredTypeIdentifiers = [UTType.data.identifier]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should return attachment resolution with temp file
        XCTAssertNotNil(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result!.url.path))
        XCTAssertEqual(result?.type, .data)

        // Verify file content
        let fileData = try Data(contentsOf: result!.url)
        XCTAssertEqual(fileData, testData)

        // Cleanup
        try FileManager.default.removeItem(at: result!.url)
    }

    func testResolveAttachmentFailure() async throws {
        // Given: A mock provider with no attachment types
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    // MARK: - Helper Method Tests

    func testWriteTemp() throws {
        // Given: Test data and extension
        let testData = "Test temp file".data(using: .utf8)!
        let ext = "txt"

        // When: Writing temp file
        let url = try AttachmentResolver.writeTemp(data: testData, ext: ext)

        // Then: Should create file with correct content
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == ext)

        let fileData = try Data(contentsOf: url)
        XCTAssertEqual(fileData, testData)

        // Cleanup
        try FileManager.default.removeItem(at: url)
    }

    func testWriteTempWithBinaryData() throws {
        // Given: Binary data
        let testData = Data([0x00, 0x01, 0x02, 0x03, 0xFF])
        let ext = "bin"

        // When: Writing temp file
        let url = try AttachmentResolver.writeTemp(data: testData, ext: ext)

        // Then: Should create file with correct content
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == ext)

        let fileData = try Data(contentsOf: url)
        XCTAssertEqual(fileData, testData)

        // Cleanup
        try FileManager.default.removeItem(at: url)
    }

    // MARK: - Edge Cases and Error Handling

    func testResolveTextWithInvalidEncoding() async throws {
        // Given: A mock provider with invalid UTF-8 data
        let invalidData = Data([0xFF, 0xFE, 0xFD])  // Invalid UTF-8
        let mockProvider = MockNSItemProvider()
        mockProvider.mockData = invalidData
        mockProvider.registeredTypeIdentifiers = [UTType.data.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return nil (invalid encoding)
        XCTAssertNil(result)
    }

    func testResolveAttachmentWithUnsupportedType() async throws {
        // Given: A mock provider with unsupported type
        let mockProvider = MockNSItemProvider()
        mockProvider.registeredTypeIdentifiers = ["com.unsupported.type"]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    func testResolveTextWithEmptyString() async throws {
        // Given: A mock provider with empty text
        let mockProvider = MockNSItemProvider()
        mockProvider.mockText = ""
        mockProvider.registeredTypeIdentifiers = [UTType.plainText.identifier]

        // When: Resolving text
        let result = try await AttachmentResolver.resolveText(from: mockProvider)

        // Then: Should return empty string
        XCTAssertEqual(result, "")
    }

    func testResolveAttachmentWithLargeFile() async throws {
        // Given: A mock provider with large data
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)  // 1MB
        let mockProvider = MockNSItemProvider()
        mockProvider.mockData = largeData
        mockProvider.registeredTypeIdentifiers = [UTType.data.identifier]

        // When: Resolving attachment
        let result = try await AttachmentResolver.resolveAttachment(from: mockProvider)

        // Then: Should handle large file
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .data)

        // Verify file size
        let fileData = try Data(contentsOf: result!.url)
        XCTAssertEqual(fileData.count, largeData.count)

        // Cleanup
        try FileManager.default.removeItem(at: result!.url)
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
            XCTFail("Failed to create temp file: \(error)")
            return fileURL
        }
    }
}
