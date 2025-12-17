//
//  TestPhotoAttachments.swift
//  Three Daily GoalsTests
//
//  Tests for photo attachment functionality including camera and photo library
//

import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers

@testable import Three_Daily_Goals
@testable import tdgCoreMain
import tdgCoreWidget

@Suite
@MainActor
struct TestPhotoAttachments {

    // MARK: - Setup Helpers

    func createTestAppComponents() -> AppComponents {
        return setupApp(isTesting: true)
    }

    func createTestTask(in context: ModelContext, timeProvider: TimeProvider) -> TaskItem {
        let task = TaskItem()
        task.setTitle("Test Task")
        context.insert(task)
        try? context.save()
        return task
    }

    func createTestImageData() -> Data {
        // Create a minimal 1x1 JPEG image data
        let size = CGSize(width: 1, height: 1)
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            PlatformColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
        #else
        // macOS: Create test data
        return Data([0xFF, 0xD8, 0xFF, 0xE0]) // Minimal JPEG header
        #endif
    }

    // MARK: - Attachment Creation Tests

    @Test
    func testAddPhotoAttachment() throws {
        // Given: Test app components and a task
        let appComponents = createTestAppComponents()
        let context = appComponents.modelContainer.mainContext
        let task = createTestTask(in: context, timeProvider: appComponents.timeProviderWrapper.timeProvider)

        // When: Adding a photo attachment
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "test_photo_\(Date().timeIntervalSince1970).jpg"
        let tempURL = tempDir.appendingPathComponent(filename)

        let testData = createTestImageData()
        try testData.write(to: tempURL)

        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .jpeg,
            to: task,
            in: context
        )

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)

        // Then: Attachment should be created
        #expect(attachment.filename.contains("test_photo"), "Filename should contain test_photo")
        #expect(attachment.utiIdentifier == UTType.jpeg.identifier, "Should be JPEG type")
        #expect(task.attachments?.contains(where: { $0.id == attachment.id }) == true, "Task should contain attachment")
    }

    @Test
    func testMultiplePhotoAttachments() throws {
        // Given: Test app components and a task
        let appComponents = createTestAppComponents()
        let context = appComponents.modelContainer.mainContext
        let task = createTestTask(in: context, timeProvider: appComponents.timeProviderWrapper.timeProvider)

        // When: Adding multiple photo attachments
        let photoCount = 3
        for i in 0..<photoCount {
            let tempDir = FileManager.default.temporaryDirectory
            let filename = "test_photo_\(Date().timeIntervalSince1970)_\(i).jpg"
            let tempURL = tempDir.appendingPathComponent(filename)

            let testData = createTestImageData()
            try testData.write(to: tempURL)

            _ = try addAttachment(
                fileURL: tempURL,
                type: .jpeg,
                to: task,
                sortIndex: i,
                in: context
            )

            try? FileManager.default.removeItem(at: tempURL)
        }

        // Then: All attachments should be added
        #expect(task.attachments?.count == photoCount, "Should have \(photoCount) attachments")
    }

    @Test
    func testPhotoAttachmentWithComment() throws {
        // Given: Test app components and a task
        let appComponents = createTestAppComponents()
        let context = appComponents.modelContainer.mainContext
        let task = createTestTask(in: context, timeProvider: appComponents.timeProviderWrapper.timeProvider)

        let initialCommentCount = task.comments?.count ?? 0

        // When: Adding a photo attachment and a comment
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "test_photo_comment.jpg"
        let tempURL = tempDir.appendingPathComponent(filename)

        let testData = createTestImageData()
        try testData.write(to: tempURL)

        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .jpeg,
            to: task,
            in: context
        )

        task.addComment(text: "Added photo: \(attachment.filename)", icon: imgAttachment)

        try? FileManager.default.removeItem(at: tempURL)

        // Then: Comment should be added
        let finalCommentCount = task.comments?.count ?? 0
        #expect(finalCommentCount == initialCommentCount + 1, "Should have one more comment")

        let lastComment = task.comments?.last
        #expect(lastComment?.text.contains("Added photo") == true, "Comment should mention added photo")
    }

    // MARK: - File Cleanup Tests

    @Test
    func testTempFileCleanup() throws {
        // Given: A temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "test_cleanup_\(UUID().uuidString).jpg"
        let tempURL = tempDir.appendingPathComponent(filename)

        let testData = createTestImageData()
        try testData.write(to: tempURL)

        // When: File exists
        #expect(FileManager.default.fileExists(atPath: tempURL.path), "Temp file should exist")

        // When: Cleaning up
        try FileManager.default.removeItem(at: tempURL)

        // Then: File should be removed
        #expect(!FileManager.default.fileExists(atPath: tempURL.path), "Temp file should be removed")
    }

    // MARK: - JPEG Compression Tests

    @Test
    func testJPEGCompressionQuality() throws {
        #if os(iOS)
        // Given: An image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            PlatformColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        // When: Compressing at different quality levels
        let highQuality = image.jpegData(compressionQuality: 1.0)
        let mediumQuality = image.jpegData(compressionQuality: 0.8)
        let lowQuality = image.jpegData(compressionQuality: 0.5)

        // Then: File sizes should decrease with quality
        #expect(highQuality != nil, "High quality data should exist")
        #expect(mediumQuality != nil, "Medium quality data should exist")
        #expect(lowQuality != nil, "Low quality data should exist")

        if let high = highQuality, let medium = mediumQuality, let low = lowQuality {
            #expect(high.count > medium.count, "High quality should be larger than medium")
            #expect(medium.count > low.count, "Medium quality should be larger than low")
        }
        #endif
    }

    // MARK: - Error Handling Tests

    @Test
    func testInvalidImageData() throws {
        // Given: Invalid image data
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        // When: Attempting to create image from invalid data
        let image = PlatformImage(data: invalidData)
        #endif

        // Then: Should fail gracefully
        #expect(image == nil, "Should not create image from invalid data")
    }

    @Test
    func testAttachmentSizeLimit() throws {
        // Given: Test app components and a task
        let appComponents = createTestAppComponents()
        let context = appComponents.modelContainer.mainContext
        let task = createTestTask(in: context, timeProvider: appComponents.timeProviderWrapper.timeProvider)

        // When: Creating a large file
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "large_file.jpg"
        let tempURL = tempDir.appendingPathComponent(filename)

        // Create 25MB file (over default 20MB limit)
        let largeData = Data(repeating: 0xFF, count: 25 * 1024 * 1024)
        try largeData.write(to: tempURL)

        // Then: Should throw an error
        do {
            _ = try addAttachment(
                fileURL: tempURL,
                type: .jpeg,
                to: task,
                in: context
            )
            #expect(Bool(false), "Should have thrown error for large file")
        } catch {
            // Expected to fail - test passes if we reach here
        }

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Filename Generation Tests

    @Test
    func testTimestampFilenameGeneration() throws {
        // Given: Multiple timestamps
        let timestamp1 = Date().timeIntervalSince1970
        Thread.sleep(forTimeInterval: 0.01) // Small delay
        let timestamp2 = Date().timeIntervalSince1970

        // When: Generating filenames
        let filename1 = "photo_\(timestamp1)_0.jpg"
        let filename2 = "photo_\(timestamp2)_0.jpg"

        // Then: Filenames should be different
        #expect(filename1 != filename2, "Filenames should be unique")
    }

    @Test
    func testFilenameWithIndex() throws {
        // Given: Multiple photos with indices
        let timestamp = Date().timeIntervalSince1970

        // When: Generating filenames with indices
        let filenames = (0..<5).map { index in
            "photo_\(timestamp)_\(index).jpg"
        }

        // Then: All filenames should be unique
        let uniqueFilenames = Set(filenames)
        #expect(uniqueFilenames.count == 5, "All filenames should be unique")
    }

    // MARK: - UTType Tests

    @Test
    func testJPEGTypeIdentification() throws {
        // Given: JPEG UTType
        let jpegType = UTType.jpeg

        // When: Checking identifier
        let identifier = jpegType.identifier

        // Then: Should match expected identifier
        #expect(identifier == "public.jpeg", "JPEG identifier should be public.jpeg")
        #expect(jpegType.conforms(to: .image), "JPEG should conform to image type")
    }

    @Test
    func testImageTypeConformance() throws {
        // Given: Various image types
        let types: [UTType] = [.jpeg, .png, .heic, .gif]

        // When: Checking conformance
        let allConformToImage = types.allSatisfy { $0.conforms(to: .image) }

        // Then: All should conform to image
        #expect(allConformToImage, "All image types should conform to .image")
    }
}
