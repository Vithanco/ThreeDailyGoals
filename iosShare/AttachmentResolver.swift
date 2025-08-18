//
//  AttachmentResolver.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/08/2025.
//

import Foundation
import UniformTypeIdentifiers

struct AttachmentResolution {
    let url: URL
    let type: UTType
}

enum AttachmentResolver {

    // URL / Text
    static func resolveURL(from p: NSItemProvider) async throws -> URL? {
        try await withCheckedThrowingContinuation { c in
            p.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, err in
                if let err = err {
                    c.resume(throwing: err)
                    return
                }
                c.resume(returning: item as? URL)
            }
        }
    }

    static func resolveText(from p: NSItemProvider) async throws -> String? {
        if let d = try await loadDataRepresentation(for: .plainText, from: p),
            let s = String(data: d, encoding: .utf8)
        {
            return s
        }
        if let d = try await loadDataRepresentation(for: .text, from: p),
            let s = String(data: d, encoding: .utf8)
        {
            return s
        }
        return try await withCheckedThrowingContinuation { c in
            p.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, err in
                if let err = err {
                    c.resume(throwing: err)
                    return
                }
                if let s = item as? String {
                    c.resume(returning: s)
                    return
                }
                if let url = item as? URL, let s = try? String(contentsOf: url) {
                    c.resume(returning: s)
                    return
                }
                if let d = item as? Data, let s = String(data: d, encoding: .utf8) {
                    c.resume(returning: s)
                    return
                }
                c.resume(returning: nil)
            }
        }
    }

    // Attachments → (fileURL, UTType)
    static func resolveAttachment(from p: NSItemProvider) async throws -> AttachmentResolution? {
        if let url = try await loadFile(for: [.movie, .video, .pdf, .image], from: p) {
            return .init(url: url, type: inferType(from: url) ?? .data)
        }
        if let url = try await loadFileURL(from: p) {
            return .init(url: url, type: inferType(from: url) ?? .data)
        }
        if let payload = try await loadData(from: p) {
            let ext = payload.type.preferredFilenameExtension ?? "bin"
            let url = try writeTemp(data: payload.data, ext: ext)
            return .init(url: url, type: payload.type)
        }
        return nil
    }

    // MARK: - Helpers

    private static func loadFileURL(from p: NSItemProvider) async throws -> URL? {
        try await withCheckedThrowingContinuation { c in
            p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, err in
                if let err = err {
                    c.resume(throwing: err)
                    return
                }
                c.resume(returning: item as? URL)
            }
        }
    }

    private static func loadFile(for types: [UTType], from p: NSItemProvider) async throws -> URL? {
        for t in types where p.hasItemConformingToTypeIdentifier(t.identifier) {
            return try await withCheckedThrowingContinuation { c in
                p.loadFileRepresentation(forTypeIdentifier: t.identifier) { src, err in
                    if let err = err {
                        c.resume(throwing: err)
                        return
                    }
                    guard let src else {
                        c.resume(returning: nil)
                        return
                    }
                    let dst = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(src.pathExtension)
                    do {
                        if FileManager.default.fileExists(atPath: dst.path) {
                            try FileManager.default.removeItem(at: dst)
                        }
                        try FileManager.default.copyItem(at: src, to: dst)
                        c.resume(returning: dst)
                    } catch { c.resume(throwing: error) }
                }
            }
        }
        return nil
    }

    private static func loadData(from p: NSItemProvider) async throws -> (data: Data, type: UTType)? {
        if let d = try await loadDataRepresentation(for: .data, from: p) { return (d, .data) }
        if let d = try await loadDataRepresentation(for: .item, from: p) { return (d, .item) }
        return nil
    }

    private static func loadDataRepresentation(for type: UTType, from p: NSItemProvider) async throws -> Data? {
        try await withCheckedThrowingContinuation { c in
            p.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, err in
                if let err = err {
                    c.resume(throwing: err)
                    return
                }
                c.resume(returning: data)
            }
        }
    }

    private static func inferType(from url: URL) -> UTType? {
        if let t = UTType(filenameExtension: url.pathExtension.lowercased()) { return t }
        if let uti = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            return UTType(importedAs: uti)
        }
        return nil
    }

    public static func writeTemp(data: Data, ext: String) throws -> URL {
        let dst = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        try data.write(to: dst, options: .atomic)
        return dst
    }
}
