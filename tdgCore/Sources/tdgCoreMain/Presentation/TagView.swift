//
//  TagView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/09/2025.
//

import SwiftUI

public struct TagView: View {
    let text: String
    let isSelected: Bool
    let accentColor: Color  // kept for API compatibility; rendering always uses Color.accent
    let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    #if os(macOS)
        @State private var isHovered = false
    #endif

    public init(text: String, isSelected: Bool = false, accentColor: Color = .primary, onTap: (() -> Void)? = nil) {
        self.text = text
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.onTap = onTap
    }

    // Selected:   solid #EA580C  (.tdg-tag)
    // Unselected: rgba(234,88,12,0.1) tint + dark-orange text  (.pv-tag)
    private var chipBackground: Color {
        isSelected ? Color.accent : Color.accent.opacity(0.1)
    }

    private var chipForeground: Color {
        if isSelected { return .white }
        // #B84509 in light; the accent itself (bright enough) in dark
        return colorScheme == .dark
            ? Color.accent.opacity(0.9)
            : Color(red: 184 / 255, green: 69 / 255, blue: 9 / 255)
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(chipBackground)
                )
                .foregroundStyle(chipForeground)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .buttonStyle(.plain)
        #if os(macOS)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
        #endif
    }
}

#Preview {
    VStack(spacing: 8) {
        HStack(spacing: 4) {
            TagView(text: "work", isSelected: true, accentColor: .blue)
            TagView(text: "private", isSelected: false, accentColor: .blue)
            TagView(text: "health", isSelected: true, accentColor: .green)
        }

        HStack(spacing: 4) {
            TagView(text: "movie", isSelected: false, accentColor: .red)
            TagView(text: "obsidian", isSelected: true, accentColor: .purple)
        }
    }
    .padding()
}
