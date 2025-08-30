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

enum SharePayload {
    case url(String)
    case text(String)
    case attachment(URL, UTType)
}

enum ShareFlow {
    public static func resolve(from provider: NSItemProvider) async throws -> SharePayload? {
        // URL first
        if let url = try await AttachmentResolver.resolveURL(from: provider) {
            return .url(url.absoluteString)
        }
        // Prefer attachments (now includes .html)
        if let a = try await AttachmentResolver.resolveAttachment(from: provider) {
            return .attachment(a.url, a.type)
        }
        // Text last — but if it *looks like HTML*, turn it into a file
        if let t = try await AttachmentResolver.resolveText(from: provider) {
            if looksLikeHTML(t) {
                let url = try AttachmentResolver.writeTemp(data: Data(t.utf8), ext: "html")
                return .attachment(url, .html)
            }
            return .text(t)
        }
        return nil
    }

    private static func looksLikeHTML(_ s: String) -> Bool {
        let lower = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.hasPrefix("<!doctype html") || lower.hasPrefix("<html") || lower.contains("<head>")
            || lower.contains("<body>")
    }

}
