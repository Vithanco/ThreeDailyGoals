//
//  PlatformTypes.swift
//  tdgCoreWidget
//
//  Centralized platform-specific type aliases and imports
//  This file provides a single source of truth for platform differences
//

import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
    public typealias PlatformImage = UIImage
    public typealias PlatformColor = UIColor
    public typealias PlatformView = UIView
    public typealias PlatformViewController = UIViewController
    public typealias PlatformImagePickerController = UIImagePickerController
#elseif os(macOS)
    import AppKit
    public typealias PlatformImage = NSImage
    public typealias PlatformColor = NSColor
    public typealias PlatformView = NSView
    public typealias PlatformViewController = NSViewController
#endif

// MARK: - Platform-Specific Image Extensions

extension PlatformImage {
    #if os(macOS)
        /// Returns the CGImage representation on macOS (UIImage has this property natively on iOS)
        public var cgImage: CGImage? {
            return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }

        /// Creates a PNG data representation (compatible with iOS UIImage.pngData())
        public func pngData() -> Data? {
            guard let tiffRepresentation = self.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
            else {
                return nil
            }
            return bitmapImage.representation(using: .png, properties: [:])
        }

        /// Creates a JPEG data representation with compression quality (compatible with iOS UIImage.jpegData())
        public func jpegData(compressionQuality: CGFloat) -> Data? {
            guard let tiffRepresentation = self.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
            else {
                return nil
            }
            return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        }
    #endif
}

// MARK: - Platform-Specific File System Helpers

public struct PlatformFileSystem {
    /// Returns the appropriate temporary directory path for the current platform
    public static var temporaryDirectory: URL {
        #if os(iOS)
            // On iOS, use the app's documents directory for better file access
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #else
            // On macOS, use temporary directory
            return URL(fileURLWithPath: NSTemporaryDirectory())
        #endif
    }

    /// Opens a URL using the platform-specific method
    public static func openURL(_ url: URL) {
        #if os(iOS)
            UIApplication.shared.open(url)
        #elseif os(macOS)
            NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Platform Capability Checks

public struct PlatformCapabilities {
    /// Whether the current platform supports camera capture
    public static var supportsCamera: Bool {
        #if os(iOS)
            return UIImagePickerController.isSourceTypeAvailable(.camera)
        #else
            return false
        #endif
    }

    /// Whether the current platform supports dedicated windows (vs sheets/covers)
    public static var supportsDedicatedWindows: Bool {
        #if os(macOS)
            return true
        #else
            return false
        #endif
    }
}
