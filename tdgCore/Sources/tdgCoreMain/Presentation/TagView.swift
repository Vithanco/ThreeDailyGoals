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
    let accentColor: Color
    let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    public init(text: String, isSelected: Bool = false, accentColor: Color = .primary, onTap: (() -> Void)? = nil) {
        self.text = text
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.onTap = onTap
    }

    public var body: some View {
        Text(text)
            .padding(.horizontal, 2)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isSelected
                            ? accentColor.opacity(0.2)
                            : (colorScheme == .dark ? Color.neutral700.opacity(0.3) : Color.neutral200.opacity(0.5)))
            )
            .foregroundColor(isSelected ? accentColor : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected
                            ? accentColor
                            : (colorScheme == .dark ? Color.neutral600.opacity(0.6) : Color.neutral400.opacity(0.6)),
                        lineWidth: 1)
            )
            .lineLimit(1)  // Prevent text wrapping
            .truncationMode(.tail)  // Truncate with ellipsis if needed
            .onTapGesture {
                onTap?()
            }
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
