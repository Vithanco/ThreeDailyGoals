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
        ScrollView {
            Group {
                #if os(iOS)
                // iOS: Stacked vertical layout for narrow screens
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
                    
                    // History section
                    AllCommentsView(item: item)
                }
                #else
                // macOS: Side-by-side layout for wide screens
                HStack(alignment: .top, spacing: 20) {
                    // Main task content with enhanced card styling
                    InnerTaskItemView(
                        accentColor: preferences.accentColor,
                        item: item,
                        allTags: dataManager.activeTags.asArray,
                        selectedTagStyle: selectedTagStyle(accentColor: preferences.accentColor),
                        missingTagStyle: missingTagStyle,
                        showAttachmentImport: true
                    )
                    .frame(maxWidth: .infinity)
                    
                    // History section
                    AllCommentsView(item: item)
                        .frame(maxWidth: .infinity)
                }
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .itemToolbar(item: item)
        .onAppear(perform: {
            dataManager.updateUndoRedoStatus()
            isTitleFocused = true
        })
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TaskItem.self, configurations: config)
    
    let item = TaskItem(title: "Sample Task", state: .open)
    
    return TaskItemView(item: item)
        .modelContainer(container)
        .environment(dummyViewModel())
}
