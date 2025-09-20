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

    #if os(macOS)
        return true
    #elseif os(watchOS)
        return false
    #else
        guard UIScreen.main.bounds.width > 1000 else {
            return false
        }
        return true
    #endif
}
