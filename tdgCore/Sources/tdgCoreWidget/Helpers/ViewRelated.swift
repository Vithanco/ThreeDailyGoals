//
//  ViewRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 24/12/2023.
//

import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
#endif

@MainActor
public var isLargeDevice: Bool {
    #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
    #elseif os(macOS)
        return true
    #else
        return false
    #endif
}
