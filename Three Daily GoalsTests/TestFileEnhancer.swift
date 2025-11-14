//
//  TestFileEnhancer.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 30/10/2025.
//

import Foundation
import PDFKit
import Testing
import UniformTypeIdentifiers

@testable import tdgCoreMain

@Suite("FileEnhancer Tests")
struct TestFileEnhancer {
    // MARK: - Text File Tests

    @Test("Plain text file generates description with line and character counts")
    func testPlainTextFileDescription() async throws {
        let enhancer = FileEnhancer()
        let content = "Line 1\nLine 2\nLine 3\n\nLine 5"
        let fileURL = createTempFile(content: content, extension: "txt")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .plainText, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("4 lines") == true)
        #expect(description?.contains("27 characters") == true)
    }

    @Test("Swift source code file is detected as text")
    func testSwiftSourceCodeDetection() async throws {
        let enhancer = FileEnhancer()
        let content = "import Foundation\n\nfunc test() {\n    print(\"Hello\")\n}"
        let fileURL = createTempFile(content: content, extension: "swift")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("lines") == true)
    }

    @Test("TypeScript file is detected as text")
    func testTypeScriptDetection() async throws {
        let enhancer = FileEnhancer()
        let content = "const x: number = 42;\nconsole.log(x);"
        let fileURL = createTempFile(content: content, extension: "ts")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("lines") == true)
    }

    @Test("Markdown file is detected as text")
    func testMarkdownDetection() async throws {
        let enhancer = FileEnhancer()
        let content = "# Title\n\nSome content here."
        let fileURL = createTempFile(content: content, extension: "md")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("lines") == true)
    }

    @Test("Empty text file is handled gracefully")
    func testEmptyTextFile() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(content: "", extension: "txt")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .plainText, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("0 lines") == true)
    }

    // MARK: - Binary File Tests

    @Test("PDF file returns PDF document description")
    func testPDFDescription() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(data: minimalPDFData(), extension: "pdf")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .pdf, useAI: false)

        #expect(description == "PDF document")
    }

    @Test("PNG image file returns image description")
    func testPNGDescription() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(data: minimalPNGData(), extension: "png")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .png, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("Image file") == true)
    }

    @Test("JPEG image file returns image description")
    func testJPEGDescription() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(data: minimalJPEGData(), extension: "jpg")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .jpeg, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("Image file") == true)
    }

    @Test("MP4 video file returns video description")
    func testMP4Description() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(data: minimalMP4Data(), extension: "mp4")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .mpeg4Movie, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("Video file") == true)
    }

    @Test("MP3 audio file returns audio description")
    func testMP3Description() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(data: minimalMP3Data(), extension: "mp3")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .mp3, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("Audio file") == true)
    }

    @Test("ZIP archive file returns archive description")
    func testZIPDescription() async throws {
        let enhancer = FileEnhancer()
        let fileURL = createTempFile(data: minimalZIPData(), extension: "zip")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .zip, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("Archive file") == true)
    }

    // MARK: - Edge Cases

    @Test("Unknown binary file gets generic description")
    func testUnknownBinaryFile() async throws {
        let enhancer = FileEnhancer()
        let binaryData = Data([0xFF, 0xFE, 0xFD, 0xFC, 0x00, 0x01])
        let fileURL = createTempFile(data: binaryData, extension: "dat")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, useAI: false)

        #expect(description != nil)
    }

    @Test("Binary file with text-like extension detected correctly by content")
    func testBinaryWithTextExtension() async throws {
        let enhancer = FileEnhancer()
        let binaryData = Data([0xFF, 0xFE, 0xFD, 0xFC, 0x00, 0x01])
        let fileURL = createTempFile(data: binaryData, extension: "txt")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, useAI: false)

        #expect(description != nil)
    }

    @Test("Non-existent file returns nil")
    func testNonExistentFile() async throws {
        let enhancer = FileEnhancer()
        let fileURL = URL(fileURLWithPath: "/tmp/this-file-does-not-exist-\(UUID().uuidString).txt")

        let description = await enhancer.enhance(fileURL: fileURL, useAI: false)

        #expect(description == nil)
    }

    @Test("File with only whitespace is handled correctly")
    func testWhitespaceOnlyFile() async throws {
        let enhancer = FileEnhancer()
        let content = "   \n  \n\t\n   "
        let fileURL = createTempFile(content: content, extension: "txt")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let description = await enhancer.enhance(fileURL: fileURL, contentType: .plainText, useAI: false)

        #expect(description != nil)
        #expect(description?.contains("0 lines") == true)
    }

    // MARK: - Helper Methods

    private func createTempFile(content: String, extension fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func createTempFile(data: Data, extension fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)
        try! data.write(to: fileURL)
        return fileURL
    }

    /// Minimal valid 1-page PDF file (for PDFKit to open)
    private func minimalPDFData() -> Data {
        // "%PDF-1.3\n%âãÏÓ\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\nstartxref\n9\n%%EOF\n"
        return Data([
            0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x33, 0x0A,
            0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
            0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A,
            0x3C, 0x3C, 0x3E, 0x3E, 0x0A,
            0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
            0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72, 0x0A,
            0x3C, 0x3C, 0x3E, 0x3E, 0x0A,
            0x73, 0x74, 0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66, 0x0A,
            0x39, 0x0A, 0x25, 0x25, 0x45, 0x4F, 0x46, 0x0A,
        ])
    }

    /// Minimal valid PNG file (with header)
    private func minimalPNGData() -> Data {
        return Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
            0x54, 0x08, 0xD7, 0x63, 0x60, 0x00, 0x00, 0x00,
            0x02, 0x00, 0x01, 0xE2, 0x26, 0x05, 0x9B, 0x00,
            0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
            0x42, 0x60, 0x82,
        ])
    }

    /// Minimal valid JPEG header
    private func minimalJPEGData() -> Data {
        return Data([
            0xFF, 0xD8,  // SOI marker
            0xFF, 0xE0,  // APP0 marker
            0x00, 0x10,  // length
            0x4A, 0x46, 0x49, 0x46, 0x00,  // "JFIF" identifier
            0x01, 0x01,  // version
            0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
            0xFF, 0xD9,  // EOI marker
        ])
    }

    /// Minimal valid MP4 header (not a real video, just for UTType/classification)
    private func minimalMP4Data() -> Data {
        return Data([
            0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70,
            0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00,
            0x6D, 0x70, 0x34, 0x32, 0x69, 0x73, 0x6F, 0x6D,
        ])
    }

    /// Minimal valid MP3 header
    private func minimalMP3Data() -> Data {
        return Data([
            0x49, 0x44, 0x33,  // ID3 tag
            0x03, 0x00, 0x00, 0x00, 0x00, 0x21, 0x76,
        ])
    }

    /// Minimal valid ZIP header
    private func minimalZIPData() -> Data {
        return Data([
            0x50, 0x4B, 0x03, 0x04,
            0x14, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
        ])
    }
}
