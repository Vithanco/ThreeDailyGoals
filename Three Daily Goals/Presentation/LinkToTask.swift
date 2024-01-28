//
//  LinkToTask.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import SwiftUI

struct LinkToTask: View {
    @Bindable var model: TaskManagerViewModel
    @Bindable var item: TaskItem
    let list: TaskItemState
    
    var body: some View {
#if os(macOS)
        TaskAsLine(item: item, accentColor: model.accentColor).onTapGesture {
            model.select(which: list, item: item)
        }
#endif
#if os(iOS)
        NavigationLink {
            TaskItemView(model: model, item: item)
        } label: {
            TaskAsLine(item: item, accentColor: model.accentColor)
        }
#endif
        
        
        
    }
}

@MainActor fileprivate struct LinkToTaskHelper : View {
    @State var model = TaskManagerViewModel(modelContext: TestStorage())
    
    var body: some View {
        LinkToTask(model: model, item: model.items.first ?? TaskItem(), list: .open)
    }
}

#Preview {
    LinkToTaskHelper()
}
