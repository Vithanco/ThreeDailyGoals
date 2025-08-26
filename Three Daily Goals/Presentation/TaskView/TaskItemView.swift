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
    @Bindable var item: TaskItem
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack {
            InnerTaskItemView(
                accentColor: preferences.accentColor,
                item: item,
                allTags: dataManager.activeTags.asArray,
                selectedTagStyle: selectedTagStyle(accentColor: preferences.accentColor),
                missingTagStyle: missingTagStyle,
                showAttachmentImport: true
            )
            
            AllCommentsView(item: item).frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()

                        HStack {
                            Spacer()
                            LabeledContent {
                                Text(item.created, format: stdOnlyDateFormat)
                            } label: {
                                Text("Created:").bold().foregroundColor(Color.secondaryColor)
                            }
                            Spacer()
                            LabeledContent {
                                Text(item.changed.timeAgoDisplay())
                            } label: {
                                Text("Changed:").bold().foregroundColor(Color.secondaryColor)
                            }
                            Spacer()
                        }.padding(.bottom, 8)
        }
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
