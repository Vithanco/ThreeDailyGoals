//
//  tdgCoreShare.swift
//  tdgCoreShare
//
//  Created by Klaus Kneupner on 17/09/2025.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
// Re-export everything from tdgCoreMain for full functionality
@_exported import tdgCoreMain

#if os(iOS)
    import UIKit
    public typealias BaseViewController = UIViewController
    public typealias HostingController = UIHostingController
#elseif os(macOS)
    import AppKit
    public typealias BaseViewController = NSViewController
    public typealias HostingController = NSHostingController
#endif
