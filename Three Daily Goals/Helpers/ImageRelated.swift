import Foundation
import SwiftUI
import UniformTypeIdentifiers
import QuickLookThumbnailing
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Image {
    init?(data: Data) {
        #if canImport(UIKit)
        guard let ui = UIImage(data: data) else { return nil }
        self = Image(uiImage: ui)
        #elseif canImport(AppKit)
        guard let ns = NSImage(data: data) else { return nil }
        self = Image(nsImage: ns)
        #else
        return nil
        #endif
    }
}

/// Create a SwiftUI Image from a QL thumbnail representation.
@inline(__always)
func image(from rep: QLThumbnailRepresentation) -> Image {
    #if canImport(UIKit)
    Image(uiImage: rep.uiImage)
    #elseif canImport(AppKit)
    Image(nsImage: rep.nsImage)
    #endif
}

/// Generate a Quick Look thumbnail as a SwiftUI Image.
func qlThumbnailImage(
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

func makeThumbnail(from data: Data, type: UTType, maxSide: CGFloat = 160) -> Data? {
    #if canImport(UIKit)
    if type.conforms(to: .image),
       let img = UIImage(data: data),
       let thumb = img.preparingThumbnail(of: CGSize(width: maxSide, height: maxSide)) {
        return thumb.jpegData(compressionQuality: 0.7)
    }
    #elseif canImport(AppKit)
    if type.conforms(to: .image),
       let nsImg = NSImage(data: data) {
        let size = NSSize(width: maxSide, height: maxSide)
        let scaled = NSImage(size: size)
        scaled.lockFocus()
        nsImg.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: nsImg.size),
                   operation: .copy, fraction: 1.0)
        scaled.unlockFocus()
        return scaled.tiffRepresentation
    }
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
