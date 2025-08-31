//
//  ColorRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation
import SwiftUI

extension Color {
    public static let neutral50 = Color(hex: "#FAFAFA")
    public static let neutral100 = Color(hex: "#F5F5F5")
    public static let neutral200 = Color(hex: "#EEEEEE")
    public static let neutral300 = Color(hex: "#E0E0E0")
    public static let neutral400 = Color(hex: "#BDBDBD")
    public static let neutral500 = Color(hex: "#9E9E9E")
    public static let neutral600 = Color(hex: "#757575")
    public static let neutral700 = Color(hex: "#616161")
    public static let neutral800 = Color(hex: "#424242")

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
    public static let closed = Color.green.opacity(0.7)
    public static let dead = Color.gray
    
    static let dueSoon = Color.red
    
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
