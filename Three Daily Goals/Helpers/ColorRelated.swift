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

extension Color {
    // MARK: - Primary Brand Colors (Orange-based)
    public static let primaryOrange = Color(hex: "#FF6B35")  // Vibrant orange
    public static let primaryOrangeLight = Color(hex: "#FF8A65")  // Lighter orange
    public static let primaryOrangeDark = Color(hex: "#E55A2B")  // Darker orange

    // MARK: - Semantic Task State Colors
    public static let priorityColor = Color(hex: "#FF6B35")  // Orange for priority
    public static let openColor = Color(hex: "#2196F3")  // Blue for open tasks
    public static let pendingColor = Color(hex: "#FFC107")  // Amber for pending
    public static let closedColor = Color(hex: "#4CAF50")  // Green for closed
    public static let deadColor = Color(hex: "#9E9E9E")  // Gray for dead/archived

    // MARK: - Status Colors
    public static let successColor = Color(hex: "#4CAF50")  // Green for success
    public static let warningColor = Color(hex: "#FF9800")  // Orange for warnings
    public static let errorColor = Color(hex: "#F44336")  // Red for errors
    public static let infoColor = Color(hex: "#2196F3")  // Blue for info

    // MARK: - Neutral Colors
    public static let neutral50 = Color(hex: "#FAFAFA")
    public static let neutral100 = Color(hex: "#F5F5F5")
    public static let neutral200 = Color(hex: "#EEEEEE")
    public static let neutral300 = Color(hex: "#E0E0E0")
    public static let neutral400 = Color(hex: "#BDBDBD")
    public static let neutral500 = Color(hex: "#9E9E9E")
    public static let neutral600 = Color(hex: "#757575")
    public static let neutral700 = Color(hex: "#616161")
    public static let neutral800 = Color(hex: "#424242")
    public static let neutral900 = Color(hex: "#212121")

    // MARK: - Legacy Support
    public static let mainColor = Color(
        red: 234.0 / 255.0, green: 88.0 / 255.0, blue: 12.0 / 255.0, opacity: 1.0)
    public static let secondaryColor = Color.secondary

    #if os(macOS)
        static let background = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
        static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
    
    public static let priority = Color.orange
    public static let open = Color.blue
    public static let pendingResponse = Color.yellow
    public static let closed = Color.green
    public static let dead = Color.gray

}

// MARK: - Color Theme System
struct AppColorTheme {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let text: Color
    let textSecondary: Color

    static let orange = AppColorTheme(
        primary: .primaryOrange,
        secondary: .primaryOrangeLight,
        accent: .primaryOrangeDark,
        background: .background,
        surface: .secondaryBackground,
        text: .primary,
        textSecondary: .secondary
    )

    static let blue = AppColorTheme(
        primary: .openColor,
        secondary: Color(hex: "#64B5F6"),
        accent: Color(hex: "#1976D2"),
        background: .background,
        surface: .secondaryBackground,
        text: .primary,
        textSecondary: .secondary
    )

    static let green = AppColorTheme(
        primary: .closedColor,
        secondary: Color(hex: "#81C784"),
        accent: Color(hex: "#388E3C"),
        background: .background,
        surface: .secondaryBackground,
        text: .primary,
        textSecondary: .secondary
    )
}

//from https://gist.github.com/peterfriese/bb2fc5df202f6a15cc807bd87ff15193
// Inspired by https://cocoacasts.com/from-hex-to-uicolor-and-back-in-swift
// Make Color codable. This includes support for transparency.
// See https://www.digitalocean.com/community/tutorials/css-hex-code-colors-alpha-values
extension Color {
    init(hex: String) {
        let rgba = hex.toRGBA()

        self.init(
            .sRGB,
            red: Double(rgba.r),
            green: Double(rgba.g),
            blue: Double(rgba.b),
            opacity: Double(rgba.alpha))
    }
    //
    //    public init(from decoder: Decoder) throws {
    //        let container = try decoder.singleValueContainer()
    //        let hex = try container.decode(String.self)
    //
    //        self.init(hex: hex)
    //    }
    //
    //    public func encode(to encoder: Encoder) throws {
    //        var container = encoder.singleValueContainer()
    //        try container.encode(toHex)
    //    }

    var toHex: String? {
        return toHex()
    }

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        guard alpha else {
            return String(
                format: "%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255))
        }
        return String(
            format: "%02lX%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255),
            lroundf(a * 255))
    }

    var readableTextColor: Color {
        let components = self.cgColor?.components
        let brightness =
            (components?[0] ?? 0) * 299 + (components?[1] ?? 0) * 587 + (components?[2] ?? 0) * 114
        return brightness > 500 ? .black : .white
    }

}

extension String {
    func toRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat) {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF00_0000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF_0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000_FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x0000_00FF) / 255.0
        }

        return (r, g, b, a)
    }
}
