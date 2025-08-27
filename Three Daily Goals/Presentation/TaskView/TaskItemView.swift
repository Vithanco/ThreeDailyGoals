//
//  TaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftData
import SwiftUI

struct TaskItemView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var item: TaskItem
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Main task content with enhanced card styling
            InnerTaskItemView(
                accentColor: preferences.accentColor,
                item: item,
                allTags: dataManager.activeTags.asArray,
                selectedTagStyle: selectedTagStyle(accentColor: preferences.accentColor),
                missingTagStyle: missingTagStyle,
                showAttachmentImport: true
            )

            // Comments section with metadata - same width as task content
            AllCommentsView(item: item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.neutral800 : Color.neutral50)
                        .shadow(
                            color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                            radius: colorScheme == .dark ? 8 : 6,
                            x: 0,
                            y: colorScheme == .dark ? 4 : 2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark ? Color.neutral700 : Color.neutral200,
                            lineWidth: 1
                        )
                )

            Spacer()
        }
        .padding(.horizontal, 16)
        .itemToolbar(item: item)
        .onAppear(perform: {
            dataManager.updateUndoRedoStatus()
            isTitleFocused = true
        })
    }
}

#Preview {
    //    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
    let model = dummyViewModel()

    #if os(macOS)
        return TaskItemView(item: model.dataManager.items.first()!).frame(width: 600, height: 600)
            .environment(dummyPreferences())
            .environment(DataManager.testManager())
            .environment(model)
    #endif
    #if os(iOS)
        return TaskItemView(item: model.dataManager.items.first()!)
            .environment(dummyPreferences())
            .environment(DataManager.testManager())
            .environment(model)
    #endif
}
