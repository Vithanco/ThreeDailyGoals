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
    case attachment(URL, UTType)
}

public enum ShareFlow {
    public static func resolve(from provider: NSItemProvider) async throws -> SharePayload? {
        // Log what types are available
        print("📦 Available type identifiers: \(provider.registeredTypeIdentifiers)")

        // URL first
        do {
            if let url = try await AttachmentResolver.resolveURL(from: provider) {
                print("✅ Resolved as URL: \(url.absoluteString)")
                return .url(url.absoluteString)
            } else {
                print("⚠️ resolveURL returned nil")
            }
        } catch {
            print("❌ URL resolution error: \(error)")
            // URL resolution failed, continue to next step
        }

        // Prefer attachments (now includes .html)
        do {
            if let a = try await AttachmentResolver.resolveAttachment(from: provider) {
                print("✅ Resolved as attachment: \(a.url.lastPathComponent), type: \(a.type.identifier)")
                return .attachment(a.url, a.type)
            } else {
                print("⚠️ resolveAttachment returned nil")
            }
        } catch {
            print("❌ Attachment resolution error: \(error)")
            // Attachment resolution failed, continue to next step
        }

        // Text last — but if it *looks like HTML*, turn it into a file
        do {
            if let t = try await AttachmentResolver.resolveText(from: provider) {
                print("✅ Resolved as text, length: \(t.count)")
                if looksLikeHTML(t) {
                    print("🌐 Text looks like HTML, converting to attachment")
                    let url = try AttachmentResolver.writeTemp(data: Data(t.utf8), ext: "html")
                    return .attachment(url, .html)
                }
                return .text(t)
            } else {
                print("⚠️ resolveText returned nil")
            }
        } catch {
            print("❌ Text resolution error: \(error)")
            // Text resolution failed
        }

        print("❌ All resolution methods failed")
        return nil
    }

    private static func looksLikeHTML(_ s: String) -> Bool {
        let lower = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.hasPrefix("<!doctype html") || lower.hasPrefix("<html") || lower.contains("<head>")
            || lower.contains("<body>")
    }
}
