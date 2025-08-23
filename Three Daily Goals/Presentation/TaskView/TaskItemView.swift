//
//  TaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftData
import SwiftUI

struct TaskItemView: View {
    @Bindable var model: TaskManagerViewModel
    @Bindable var item: TaskItem
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack {
            InnerTaskItemView(
                accentColor: model.accentColor,
                item: item,
                allTags: model.activeTags.asArray,
                selectedTagStyle: selectedTagStyle(accentColor: model.accentColor),
                missingTagStyle: missingTagStyle,
                showAttachmentImport: true
            )
            
            AllCommentsView(item: item).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .itemToolbar(model: model, item: item)
        .onAppear(perform: {
            model.updateUndoRedoStatus()
            isTitleFocused = true
        })
    }
}

#Preview {
    //    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
    let model = dummyViewModel()

    #if os(macOS)
        return TaskItemView(model: model, item: model.items.first()!).frame(width: 600, height: 600)
    #endif
    #if os(iOS)
        return TaskItemView(model: model, item: model.items.first()!)
    #endif
}
