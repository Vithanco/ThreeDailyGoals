//
//  ShareApp.swift
//  macosShare
//
//  Created by Klaus Kneupner on 17/09/2025.
//

import SwiftData
import SwiftUI
import tdgCoreShare

#if os(macOS)
    import AppKit
#endif

// This file provides a local alias for the tdgCoreShare.ShareExtensionView
// to maintain compatibility with the existing codebase structure
typealias ShareExtensionView = tdgCoreShare.ShareExtensionView

class ShareViewController: tdgCoreShare.ShareViewController {
    // This class inherits from tdgCoreShare.ShareViewController
    // and provides the macOS-specific implementation
}
