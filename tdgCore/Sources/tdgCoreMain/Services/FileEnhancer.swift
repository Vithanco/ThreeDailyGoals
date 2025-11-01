//
//  FileEnhancer.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 30/10/2025.
//

import Foundation
import UniformTypeIdentifiers

#if canImport(FoundationModels)
    import FoundationModels
#endif

public final class FileEnhancer: Sendable {
    private let aiSession: LanguageModelSession?

    public init() {
        #if canImport(FoundationModels)
            let model = SystemLanguageModel.default
            if case .available = model.availability {
                self.aiSession = LanguageModelSession()
            } else {
                self.aiSession = nil
            }
        #else
            self.aiSession = nil
        #endif
    }

    public var hasAI: Bool {
        return aiSession != nil
    }

    /// Generate a description for a file
    /// - Parameters:
    ///   - fileURL: The file to describe
    ///   - contentType: The UTType of the file (optional - will be detected if not provided)
    ///   - useAI: Whether to use AI for text files (default: true if available)
    /// - Returns: A description string, or nil if unable to generate
    public func enhance(fileURL: URL, contentType: UTType? = nil, useAI: Bool = true) async -> String? {
        // Detect content type if not provided
        let detectedType = contentType ?? detectFileType(from: fileURL)

        // Check if file is readable text (using UTType and fallback)
        guard isTextFile(fileURL: fileURL, contentType: detectedType) else {
            // Binary file - return type description
            return generateBinaryFileDescription(contentType: detectedType)
        }
        guard useAI && hasAI else {
            return generateBasicTextDescription(fileURL: fileURL, contentType: detectedType)
        }
        return await generateAIDescription(fileURL: fileURL)
    }

    // MARK: - File Type Detection

    /// Detect the UTType of a file using Apple's proper APIs
    private func detectFileType(from url: URL) -> UTType {
        // First, try to get type from file system resources (most reliable)
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type
        }

        // Fallback: Use extension with proper type declarations
        let ext = url.pathExtension.lowercased()

        // Map critical edge cases only
        switch ext {
        // Add custom mapping for edge-case text types if needed
        case "ts", "tsx":
            // Always treat as text (TypeScript source) for our logic
            return .plainText
        case "md", "markdown":
            return .plainText
        default:
            // Let the system try to figure it out
            return UTType(filenameExtension: ext) ?? .data
        }
    }

    // MARK: - Text File Handling

    /// Check if a file type is text-based using UTType and a fallback sniff for unknowns
    private func isTextFile(fileURL: URL, contentType: UTType) -> Bool {
        // Use UTType conformance: Apple's type hierarchy handles most text types
        let isTextLike =
            contentType.conforms(to: .text) || contentType.conforms(to: .sourceCode)
            || contentType.conforms(to: .script)

        if isTextLike {
            return true
        }

        // Fallback: For unknown types, sniff file content
        // Only peek at small files to avoid performance hit
        let maxPeekBytes = 512
        if let handle = try? FileHandle(forReadingFrom: fileURL) {
            defer { try? handle.close() }
            let data = try? handle.read(upToCount: maxPeekBytes)
            if let data, data.count > 0 {
                // If all bytes are ASCII (or UTF-8) printable or whitespace, likely text
                let allowed = Set(9...13).union(32...126)  // tab, LF, CR, space to ~
                let allText = data.allSatisfy { byte in
                    allowed.contains(Int(byte))
                }
                if allText {
                    return true
                }
            }
        }
        return false
    }

    private func generateBasicTextDescription(fileURL: URL, contentType: UTType) -> String? {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let charCount = content.count

        let typeDescription = contentType.localizedDescription ?? "Text file"
        return "\(typeDescription) with \(nonEmptyLines.count) lines (\(charCount) characters)"
    }

    private func generateAIDescription(fileURL: URL) async -> String? {
        #if canImport(FoundationModels)
            guard let session = aiSession else { return nil }

            do {
                guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                    return nil
                }

                // Limit content size for AI processing
                let truncatedContent = String(content.prefix(4000))

                let prompt = """
                    Analyze this file content and provide a brief 1-2 sentence description of what it contains and its purpose:

                    \(truncatedContent)
                    """

                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                return nil
            }
        #else
            return nil
        #endif
    }

    // MARK: - Binary File Handling

    private func generateBinaryFileDescription(contentType: UTType) -> String? {
        // Get human-readable file type description
        let typeDescription = contentType.localizedDescription ?? "File"

        // Add helpful context based on file type
        if contentType.conforms(to: .pdf) {
            return "PDF document"
        } else if contentType.conforms(to: .image) {
            return "Image file (\(typeDescription))"
        } else if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
            return "Video file (\(typeDescription))"
        } else if contentType.conforms(to: .audio) {
            return "Audio file (\(typeDescription))"
        } else if contentType.conforms(to: .archive) || contentType.conforms(to: .zip) {
            return "Archive file (\(typeDescription))"
        } else if contentType.conforms(to: .spreadsheet) {
            return "Spreadsheet (\(typeDescription))"
        } else if contentType.conforms(to: .presentation) {
            return "Presentation (\(typeDescription))"
        } else {
            return typeDescription
        }
    }
}
