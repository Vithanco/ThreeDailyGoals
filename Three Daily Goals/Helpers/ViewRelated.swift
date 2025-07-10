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

var isLargeDevice: Bool {
    #if os(macOS)
        return true
    #else
        guard UIScreen.main.bounds.width > 1000 else {
            return false
        }
        return true
    #endif
}
