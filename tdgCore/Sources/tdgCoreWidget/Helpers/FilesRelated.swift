//
//  FilesRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation

// Helper function to get the documents directory
public func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

/// Creates a temporary file URL for attachment data with platform-specific handling
/// - Parameters:
///   - data: The file data to write
///   - filename: The original filename
///   - fileExtension: The file extension (optional, will be extracted from filename if not provided)
///   - uniqueIdentifier: A unique identifier to avoid filename conflicts
/// - Returns: A URL where the file can be written, or nil if creation fails
public func createAttachmentTempFile(
    data: Data,
    filename: String,
    fileExtension: String? = nil,
    uniqueIdentifier: String
) -> URL? {
    // Check if data is empty
    guard !data.isEmpty else {
        print("Cannot create temporary file: data is empty")
        return nil
    }

    // Extract extension from filename if not provided
    let ext = fileExtension ?? URL(fileURLWithPath: filename).pathExtension

    // If we still don't have an extension, try to infer it from the filename
    let finalExt = ext.isEmpty ? URL(fileURLWithPath: filename).pathExtension : ext

    // Create a short, safe unique identifier using hash of the original identifier
    let hash = uniqueIdentifier.hashValue
    let shortIdentifier = "att_\(abs(hash))"

    // Create unique filename to avoid conflicts (limit total length)
    let maxFilenameLength = 100  // Reasonable limit for filesystem compatibility
    let availableLength = maxFilenameLength - shortIdentifier.count - 1  // -1 for underscore
    let truncatedFilename = filename.count > availableLength ? String(filename.prefix(availableLength)) : filename

    let uniqueName = "\(shortIdentifier)_\(truncatedFilename)"

    let url = PlatformFileSystem.temporaryDirectory
        .appendingPathComponent(uniqueName)
        .appendingPathExtension(finalExt)

    do {
        if !FileManager.default.fileExists(atPath: url.path) {
            try data.write(to: url, options: .atomic)
        }
        return url
    } catch {
        print("Failed to create temporary file: \(error)")
        return nil
    }
}

/// Creates a simple temporary file as a fallback when the main function fails
/// - Parameters:
///   - data: The file data to write
///   - filename: The original filename
/// - Returns: A URL where the file can be written, or nil if creation fails
public func createSimpleTempFile(data: Data, filename: String) -> URL? {
    // Extract extension from filename
    let ext = URL(fileURLWithPath: filename).pathExtension

    // Create a simple unique filename
    let uniqueName = "attachment_\(UUID().uuidString)"
    let finalName = ext.isEmpty ? uniqueName : "\(uniqueName).\(ext)"

    let url = PlatformFileSystem.temporaryDirectory
        .appendingPathComponent(finalName)

    do {
        try data.write(to: url, options: .atomic)
        return url
    } catch {
        print("Failed to create simple temporary file: \(error)")
        return nil
    }
}
