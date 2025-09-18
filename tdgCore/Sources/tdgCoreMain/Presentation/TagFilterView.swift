//
//  TagFilterView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/09/2025.
//

import SwiftUI

public struct TagFilterView: View {
    let tags: [String]
    @Binding var selectedTags: [String]
    let listColor: Color
    @Environment(\.colorScheme) private var colorScheme

    public init(tags: [String], selectedTags: Binding<[String]>, listColor: Color) {
        self.tags = tags
        self._selectedTags = selectedTags
        self.listColor = listColor
    }

    // Adaptive background color for tag container
    private var tagContainerBackground: Color {
        colorScheme == .dark ? Color.neutral700 : Color.neutral300
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: 150))], spacing: 0) {
                ForEach(tags.sorted(), id: \.self) { text in
                    let isSelected = selectedTags.contains(text)
                    TagView(
                        text: text,
                        isSelected: isSelected,
                        accentColor: listColor,
                        onTap: {
                            if let index = selectedTags.firstIndex(of: text) {
                                selectedTags.remove(at: index)
                            } else {
                                selectedTags.append(text)
                            }
                        }
                    )
                }
            }
        }
        .frame(maxHeight: 100)  // Reduced height
        .frame(maxWidth: .infinity)  // Use full width
        .padding(.horizontal, 8)
        .padding(.vertical, 6)  // Reduced vertical padding
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tagContainerBackground.opacity(0.3))
                .shadow(
                    color: colorScheme == .dark ? Color.neutral800.opacity(0.3) : Color.neutral600.opacity(0.2),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tagContainerBackground.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var selectedTags = ["work", "private"]
    let sampleTags = ["work", "private", "health", "movie", "obsidian", "3dg", "anna-lea", "vithanco"]

    TagFilterView(
        tags: sampleTags,
        selectedTags: $selectedTags,
        listColor: .blue
    )
    .padding()
}
