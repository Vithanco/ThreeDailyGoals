//
//  ImageRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import Foundation
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers
import tdgCoreWidget

extension Image {
    public init?(data: Data) {
        guard let platformImage = PlatformImage(data: data) else { return nil }
        #if canImport(UIKit)
            self = Image(uiImage: platformImage)
        #elseif canImport(AppKit)
            self = Image(nsImage: platformImage)
        #else
            return nil
        #endif
    }
}

/// Create a SwiftUI Image from a QL thumbnail representation.
@inline(__always)
public func image(from rep: QLThumbnailRepresentation) -> Image {
    #if canImport(UIKit)
        Image(uiImage: rep.uiImage)
    #elseif canImport(AppKit)
        Image(nsImage: rep.nsImage)
    #endif
}

/// Generate a Quick Look thumbnail as a SwiftUI Image.
public func qlThumbnailImage(
    for url: URL,
    size: CGSize = .init(width: 160, height: 160),
    scale: CGFloat = 0
) async -> Image? {
    let req = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .all)
    do {
        let rep = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: req)
        return image(from: rep)
    } catch {
        return nil
    }
}

public func makeThumbnail(from data: Data, type: UTType, maxSide: CGFloat = 160) -> Data? {
    guard type.conforms(to: .image),
        let img = PlatformImage(data: data)
    else {
        return nil
    }

    #if canImport(UIKit)
        if let thumb = img.preparingThumbnail(of: CGSize(width: maxSide, height: maxSide)) {
            return thumb.jpegData(compressionQuality: 0.7)
        }
    #elseif canImport(AppKit)
        let size = NSSize(width: maxSide, height: maxSide)
        let scaled = NSImage(size: size)
        scaled.lockFocus()
        img.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: img.size),
            operation: .copy, fraction: 1.0)
        scaled.unlockFocus()
        return scaled.tiffRepresentation
    #endif
    return nil
}

public struct FileThumbnailView: View {
    public let url: URL
    public let size: CGSize
    @State private var image: Image?

    public init(url: URL, size: CGSize = .init(width: 160, height: 160)) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        Group {
            if let image {
                image.resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task { image = await qlThumbnailImage(for: url, size: size) }
    }
}
