//
//  FilesRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation

// Helper function to get the documents directory
func getDocumentsDirectory() -> URL {
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
func createAttachmentTempFile(
    data: Data,
    filename: String,
    fileExtension: String? = nil,
    uniqueIdentifier: String
) -> URL? {
    // Extract extension from filename if not provided
    let ext = fileExtension ?? URL(fileURLWithPath: filename).pathExtension

    // Create a short, safe unique identifier using hash of the original identifier
    let hash = uniqueIdentifier.hashValue
    let shortIdentifier = String(format: "att_%d", abs(hash))

    // Create unique filename to avoid conflicts (limit total length)
    let maxFilenameLength = 100  // Reasonable limit for filesystem compatibility
    let availableLength = maxFilenameLength - shortIdentifier.count - 1  // -1 for underscore
    let truncatedFilename = filename.count > availableLength ? String(filename.prefix(availableLength)) : filename

    let uniqueName = "\(shortIdentifier)_\(truncatedFilename)"

    #if os(iOS)
        // On iOS, use the app's documents directory for better file access
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsPath.appendingPathComponent(uniqueName).appendingPathExtension(ext)
    #else
        // On macOS, use temporary directory
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(uniqueName)
            .appendingPathExtension(ext)
    #endif

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
