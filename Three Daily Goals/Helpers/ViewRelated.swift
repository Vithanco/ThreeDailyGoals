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
    if UIScreen.main.bounds.width > 1000 {
        return true
    } else {
        return false
    }
#endif
}
