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
    // 1) Resolve what we got from the provider
    public static func resolve(from provider: NSItemProvider) async throws -> SharePayload? {
        if let url = try await AttachmentResolver.resolveURL(from: provider) {
            return .url(url.absoluteString)
        }
        if let t = try await AttachmentResolver.resolveText(from: provider) {
            return .text(t)
        }
        if let a = try await AttachmentResolver.resolveAttachment(from: provider) {
            return .attachment(a.url, a.type)
        }
        return nil
    }

    // 2) Build a SwiftUI view (same type for all payloads)
    //    If you prefer, collapse ShareExtensionView initializers into one.
    static func makeView(
        for payload: SharePayload,
        preferences: CloudPreferences,
        container: ModelContainer
    ) -> some View {
        let view: AnyView
        switch payload {
        case .url(let s): view = AnyView(ShareExtensionView(url: s))
        case .text(let s): view = AnyView(ShareExtensionView(text: s))
        case .attachment(let u, let t):
            view = AnyView(ShareExtensionView(fileURL: u, contentType: t))
        }
        return
            view
            .environment(preferences)
            .modelContainer(container)
    }
}
