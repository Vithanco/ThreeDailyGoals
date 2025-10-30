//
//  ShareFlow.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/08/2025.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

public enum SharePayload {
    case url(String)
    case text(String)
    case attachment(URL, UTType, suggestedFilename: String?)
}

public enum ShareFlow {
    public static func resolve(from provider: NSItemProvider) async throws -> SharePayload? {
        // URL first (but file URLs should become attachments immediately)
        do {
            if let url = try await AttachmentResolver.resolveURL(from: provider) {
                guard url.isFileURL else {
                    // Web URLs
                    return .url(url.absoluteString)
                }
                // File URLs from Finder - return immediately as attachment with original filename
                let type = UTType(filenameExtension: url.pathExtension) ?? .data
                let filename = url.lastPathComponent
                return .attachment(url, type, suggestedFilename: filename)
            }
        } catch {
            // URL resolution failed, continue to next step
        }

        // Fallback: try other attachment resolution methods
        do {
            if let a = try await AttachmentResolver.resolveAttachment(from: provider) {
                return .attachment(a.url, a.type, suggestedFilename: a.suggestedFilename)
            }
        } catch {
            // Attachment resolution failed, continue to next step
        }

        // Text last — but if it *looks like HTML*, turn it into a file
        do {
            if let t = try await AttachmentResolver.resolveText(from: provider) {
                if looksLikeHTML(t) {
                    let url = try AttachmentResolver.writeTemp(data: Data(t.utf8), ext: "html")
                    return .attachment(url, .html, suggestedFilename: "content.html")
                }
                return .text(t)
            }
        } catch {
            // Text resolution failed
        }

        return nil
    }

    private static func looksLikeHTML(_ s: String) -> Bool {
        let lower = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.hasPrefix("<!doctype html") || lower.hasPrefix("<html") || lower.contains("<head>")
            || lower.contains("<body>")
    }
}
