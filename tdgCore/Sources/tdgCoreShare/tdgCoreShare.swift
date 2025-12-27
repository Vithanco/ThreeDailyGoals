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
import tdgCoreWidget

#if os(iOS)
    public typealias BaseViewController = PlatformViewController
    public typealias HostingController = UIHostingController
#elseif os(macOS)
    public typealias BaseViewController = PlatformViewController
    public typealias HostingController = NSHostingController
#endif
