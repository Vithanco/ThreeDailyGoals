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
        Button(action: {
            onTap?()
        }) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accent : Color.accent.opacity(0.18))
                )
                .foregroundStyle(isSelected ? Color.white : Color.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accent.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
                )
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .buttonStyle(.plain)
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
