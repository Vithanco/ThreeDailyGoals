//
//  ShareExtensionTestUtilities.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-15.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import tdgCoreMain
import tdgCoreShare

/// Mock NSItemProvider for testing share extension functionality
public final class MockNSItemProvider: NSItemProvider, @unchecked Sendable {
    public var mockURL: URL?
    public var mockText: String?
    public var mockFileURL: URL?
    public var mockData: Data?
    public var mockError: Error?

    private var _registeredTypeIdentifiers: [String] = []

    public override var registeredTypeIdentifiers: [String] {
        get {
            return _registeredTypeIdentifiers
        }
        set {
            _registeredTypeIdentifiers = newValue
        }
    }

    public override func hasItemConformingToTypeIdentifier(_ typeIdentifier: String) -> Bool {
        if registeredTypeIdentifiers.contains(typeIdentifier) {
            return true
        }

        for registeredType in registeredTypeIdentifiers {
            if let utType = UTType(registeredType), let requestedType = UTType(typeIdentifier) {
                if utType.conforms(to: requestedType) {
                    return true
                }
            }
        }

        return false
    }

    public override func loadItem(
        forTypeIdentifier typeIdentifier: String,
        options: [AnyHashable: Any]? = nil,
        completionHandler: NSItemProvider.CompletionHandler?
    ) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completionHandler?(
                    nil,
                    NSError(
                        domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Provider deallocated"]))
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
            case UTType.plainText.identifier, UTType.text.identifier, "public.utf8-plain-text":
                result = self.mockText as NSSecureCoding?
            case UTType.fileURL.identifier:
                result = self.mockFileURL as NSSecureCoding?
            case UTType.data.identifier, UTType.item.identifier:
                result = self.mockData as NSSecureCoding?
            default:
                if let utType = UTType(typeIdentifier), utType.conforms(to: .text) {
                    result = self.mockText as NSSecureCoding?
                } else {
                    result = nil
                }
            }

            if let result = result {
                completionHandler?(result, nil)
            } else {
                // For unsupported types, return nil with no error (not an error condition)
                completionHandler?(nil, nil)
            }
        }
    }

    public override func loadDataRepresentation(
        forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (Data?, (any Error)?) -> Void
    ) -> Progress {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completionHandler(
                    nil,
                    NSError(
                        domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Provider deallocated"]))
                return
            }

            if let error = self.mockError {
                completionHandler(nil, error)
                return
            }

            let result: Data?
            switch typeIdentifier {
            case UTType.plainText.identifier, UTType.text.identifier, "public.utf8-plain-text":
                result = self.mockText?.data(using: .utf8)
            case UTType.data.identifier, UTType.item.identifier:
                result = self.mockData
            default:
                if let utType = UTType(typeIdentifier), utType.conforms(to: .text) {
                    result = self.mockText?.data(using: .utf8)
                } else {
                    result = nil
                }
            }

            if let result = result {
                completionHandler(result, nil)
            } else {
                // For unsupported types, return nil with no error (not an error condition)
                completionHandler(nil, nil)
            }
        }
        return Progress()
    }

    public override func loadFileRepresentation(
        forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (URL?, (any Error)?) -> Void
    ) -> Progress {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completionHandler(
                    nil,
                    NSError(
                        domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Provider deallocated"]))
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
            case UTType.movie.identifier, UTType.video.identifier, UTType.pdf.identifier, UTType.image.identifier,
                UTType.html.identifier:
                result = self.mockFileURL
            default:
                result = nil
            }

            if let result = result {
                completionHandler(result, nil)
            } else {
                // For unsupported types, return nil with no error (not an error condition)
                completionHandler(nil, nil)
            }
        }
        return Progress()
    }
}

/// Test utilities and helpers for share extension testing
public struct ShareExtensionTestUtilities {

    // MARK: - Mock Data Creation

    /// Creates a mock NSItemProvider for testing
    public static func createMockProvider(
        url: URL? = nil,
        text: String? = nil,
        fileURL: URL? = nil,
        data: Data? = nil,
        error: Error? = nil,
        typeIdentifiers: [String] = []
    ) -> MockNSItemProvider {
        let provider = MockNSItemProvider()
        provider.mockURL = url
        provider.mockText = text
        provider.mockFileURL = fileURL
        provider.mockData = data
        provider.mockError = error
        provider.registeredTypeIdentifiers = typeIdentifiers
        return provider
    }

    /// Creates a temporary file for testing
    public static func createTempFile(content: String, fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            fatalError("Failed to create temp file: \(error)")
        }
    }

    /// Creates a temporary file with binary data for testing
    public static func createTempFile(data: Data, fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            fatalError("Failed to create temp file: \(error)")
        }
    }

    /// Creates test data for various file types
    public static func createTestData(for type: TestFileType) -> (content: String, extension: String, uti: UTType) {
        switch type {
        case .plainText:
            return ("This is plain text content", "txt", .plainText)
        case .html:
            return (
                "<!DOCTYPE html><html><head><title>Test</title></head><body>Hello World</body></html>", "html", .html
            )
        case .json:
            return (
                """
                {
                    "name": "Test Document",
                    "content": "This is a test JSON file",
                    "timestamp": "2025-01-15T10:00:00Z"
                }
                """, "json", .json
            )
        case .markdown:
            return (
                "# Test Document\n\nThis is a **markdown** file with some content.", "md",
                UTType(filenameExtension: "md") ?? .plainText
            )
        case .csv:
            return ("Name,Age,City\nJohn,30,New York\nJane,25,Los Angeles", "csv", .commaSeparatedText)
        }
    }

    // MARK: - Test Scenarios

    /// Creates a comprehensive test scenario for share extension testing
    public static func createTestScenario(_ scenario: ShareTestScenario) -> MockNSItemProvider {
        switch scenario {
        case .shortText:
            return createMockProvider(
                text: "Short task",
                typeIdentifiers: [UTType.plainText.identifier]
            )

        case .longText:
            return createMockProvider(
                text:
                    "This is a very long text that exceeds thirty characters and should be treated as details for the task",
                typeIdentifiers: [UTType.plainText.identifier]
            )

        case .url:
            return createMockProvider(
                url: URL(string: "https://example.com/article")!,
                typeIdentifiers: [UTType.url.identifier]
            )

        case .htmlText:
            return createMockProvider(
                text: "<!DOCTYPE html><html><head><title>Test</title></head><body>Hello World</body></html>",
                typeIdentifiers: [UTType.plainText.identifier]
            )

        case .fileAttachment(let fileType):
            let (content, ext, _) = createTestData(for: fileType)
            let tempURL = createTempFile(content: content, fileExtension: ext)
            return createMockProvider(
                fileURL: tempURL,
                typeIdentifiers: [UTType.fileURL.identifier]
            )

        case .dataAttachment(let data, let ext, _):
            let tempURL = createTempFile(data: data, fileExtension: ext)
            return createMockProvider(
                fileURL: tempURL,
                typeIdentifiers: [UTType.data.identifier]
            )

        case .error(let error):
            return createMockProvider(
                error: error,
                typeIdentifiers: [UTType.plainText.identifier]
            )

        case .unsupportedType:
            return createMockProvider(
                typeIdentifiers: ["com.unsupported.type"]
            )
        }
    }

    // MARK: - Assertion Helpers

    /// Asserts that a task was created correctly from a share operation
    public static func assertTaskCreated(
        _ task: tdgCoreMain.TaskItem,
        expectedTitle: String,
        expectedDetails: String = "",
        expectedURL: String? = nil,
        expectedAttachmentCount: Int = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assert(task.title == expectedTitle, "Task title should match expected value")
        assert(task.details == expectedDetails, "Task details should match expected value")

        if let expectedURL = expectedURL {
            assert(task.url == expectedURL, "Task URL should match expected value")
        }

        assert(
            (task.attachments?.count ?? 0) == expectedAttachmentCount, "Task should have expected number of attachments"
        )
    }

    // MARK: - Cleanup Helpers

    /// Cleans up temporary files created during testing
    public static func cleanupTempFiles(_ urls: [URL]) {
        for url in urls {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                // Ignore cleanup errors in tests
                print("Warning: Failed to cleanup temp file \(url): \(error)")
            }
        }
    }

    /// Cleans up a single temporary file
    public static func cleanupTempFile(_ url: URL) {
        cleanupTempFiles([url])
    }
}

// MARK: - Test Enums

public enum TestFileType {
    case plainText
    case html
    case json
    case markdown
    case csv
}

public enum ShareTestScenario {
    case shortText
    case longText
    case url
    case htmlText
    case fileAttachment(TestFileType)
    case dataAttachment(Data, String, UTType)
    case error(Error)
    case unsupportedType
}

// MARK: - Test Data Extensions

extension ShareTestScenario {
    /// Returns a description of the test scenario for debugging
    public var description: String {
        switch self {
        case .shortText:
            return "Short text share"
        case .longText:
            return "Long text share"
        case .url:
            return "URL share"
        case .htmlText:
            return "HTML text share"
        case .fileAttachment(let type):
            return "File attachment share (\(type))"
        case .dataAttachment(_, let ext, _):
            return "Data attachment share (.\(ext))"
        case .error(let error):
            return "Error scenario (\(error.localizedDescription))"
        case .unsupportedType:
            return "Unsupported type scenario"
        }
    }
}

extension TestFileType {
    /// Returns a description of the file type for debugging
    var description: String {
        switch self {
        case .plainText:
            return "Plain Text"
        case .html:
            return "HTML"
        case .json:
            return "JSON"
        case .markdown:
            return "Markdown"
        case .csv:
            return "CSV"
        }
    }
}
