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
        public static let background = Color(NSColor.windowBackgroundColor)
        public static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
        public static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #elseif os(ios)
        public static let background = Color(UIColor.systemBackground)
        public static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        public static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #else
        public static let background: Color = .clear
        public static let secondaryBackground: Color = .clear
        public static let tertiaryBackground: Color = .clear
    #endif

    public static let priority = Color.adaptive(light: Color(hex: "#E8900A"), dark: Color(hex: "#F5A623"))
    public static let open = Color.adaptive(light: Color(hex: "#3B82C4"), dark: Color(hex: "#5B9FE0"))
    public static let pendingResponse = Color.adaptive(light: Color(hex: "#B59A00"), dark: Color(hex: "#D4B800"))
    public static let closed = Color.adaptive(light: Color(hex: "#4A9E6A"), dark: Color(hex: "#5DC389"))
    public static let dead = Color.adaptive(light: Color(hex: "#8C7058"), dark: Color(hex: "#A8896C"))
    public static let dueSoon = Color.adaptive(light: Color(hex: "#D94F47"), dark: Color(hex: "#F06B63"))

    /// Brand accent (Tailwind orange-600) — distinct from `.priority` (system orange).
    public static let accent = Color(hex: "#EA580C")

    /// Warm cream — App Store screenshot base (#FFF9F1).
    public static let marketingCream = Color(hex: "#FFF9F1")
    /// Near-black — geometric accent in marketing materials (#111111).
    public static let marketingBlack = Color(hex: "#111111")

    // MARK: - List background tints (light mode)

    public static let listBgPriority = Color(hex: "#FFF8EE")
    public static let listBgOpen = Color(hex: "#EEF4FF")
    public static let listBgPending = Color(hex: "#FFFBEE")
    public static let listBgClosed = Color(hex: "#EEFFF3")
    public static let listBgDead = Color(hex: "#F5F0EA")

    // MARK: - Energy-Effort Matrix Colors (Muted/Toned Down)

    /// Q1: High Energy & Big Task - Deep Work (Soft lavender)
    public static let eemDeepWork = Color(hex: "#B4A5D5")

    /// Q2: Low Energy & Big Task - Steady Progress (Soft teal)
    public static let eemSteadyProgress = Color(hex: "#7BB8BA")

    /// Q3: High Energy & Small Task - Sprint Tasks (Soft coral/peach)
    public static let eemSprintTasks = Color(hex: "#F4A89A")

    /// Q4: Low Energy & Small Task - Easy Wins (Soft mint)
    public static let eemEasyWins = Color(hex: "#A8D5BA")

    /// A `Color` that resolves to `light` in light mode and `dark` in dark mode.
    public static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
            return Color(
                UIColor { traits in
                    traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
                })
        #elseif canImport(AppKit)
            return Color(
                NSColor(name: nil) { appearance in
                    let isDark =
                        appearance.bestMatch(from: [
                            .darkAqua,
                            .vibrantDark,
                            .accessibilityHighContrastDarkAqua,
                            .accessibilityHighContrastVibrantDark,
                        ]) != nil
                    return isDark ? NSColor(dark) : NSColor(light)
                })
        #else
            return light
        #endif
    }
}

//from https://gist.github.com/peterfriese/bb2fc5df202f6a15cc807bd87ff15193
// Inspired by https://cocoacasts.com/from-hex-to-uicolor-and-back-in-swift
// Make Color codable. This includes support for transparency.
// See https://www.digitalocean.com/community/tutorials/css-hex-code-colors-alpha-values
extension Color {
    public init(hex: String) {
        let rgba = hex.toRGBA()

        self.init(
            .sRGB,
            red: Double(rgba.r),
            green: Double(rgba.g),
            blue: Double(rgba.b),
            opacity: Double(rgba.alpha))
    }

    public var toHex: String? {
        return toHex()
    }

    public func toHex(alpha: Bool = false) -> String? {
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

    public var readableTextColor: Color {
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
