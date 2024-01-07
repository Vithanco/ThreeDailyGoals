//
//  ColorRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation
import SwiftUI


//
//let mainColor = Color(red: 234.0/255.0, green: 88.0/255.0, blue: 12.0/255.0, opacity: 1.0)
//let secondaryColor = Color(red: 255.0/255.0, green: 128.0/255.0, blue: 0/255.0, opacity: 1.0)


public extension Color {
//    static let backgroundColor = Color(red: 0.99, green: 0.99, blue: 0.99)   //red: 225.0 / 255.0, green: 225.0 / 255.0, blue: 235.0 / 255.0, opacity: 1.0)
    static let mainColor = Color(red: 234.0/255.0, green: 88.0/255.0, blue: 12.0/255.0, opacity: 1.0)
    static let secondaryColor = Color.secondary
    
#if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
#else
    
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
#endif
}
