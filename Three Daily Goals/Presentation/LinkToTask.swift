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
    let list: ListChooser
    
    var body: some View {
#if os(macOS)
        TaskAsLine(item: item).onTapGesture {
            model.select(which: list, item: item)
        }
#endif
#if os(iOS)
        NavigationLink {
            TaskItemView(model: model, item: item)
        } label: {
            TaskAsLine(item: item)
        }
#endif
        
        
        
    }
}

@MainActor fileprivate struct LinkToTaskHelper : View {
    @State var model = TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext).addSamples()
    
    var body: some View {
        LinkToTask(model: model, item: model.items.first ?? TaskItem(), list: .openItems)
    }
}

#Preview {
    LinkToTaskHelper()
}
