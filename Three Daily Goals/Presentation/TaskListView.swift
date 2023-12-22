//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct TaskListView: View {
    var section: [TaskSection]
    var items: [TaskItem]
#if os(macOS)
    var taskSelector: TaskSelector
#endif
    
    var body: some View {
        List {
            Section (header:
                        VStack(alignment: .leading) {
                ForEach(section) { sec in
                    sec.asText
                }
            }) {
                ForEach(items) { item in
                    #if os(macOS)
                    Text(item.title).onTapGesture {
                        taskSelector(section,items,item)
                    }
                    #endif
                    #if os(iOS)
                        LinkToTask(item: item)
                    #endif
                }
            }
        }
        
    }
}

#if os(macOS)
struct TaskListViewHelper : View {
    @State var section: [TaskSection]
    @State var items: [TaskItem]
    let taskSelector : TaskSelector
    
    var body: some View {
        
        TaskListView(section: section, items: items, taskSelector: {a, b, c in debugPrint("triggered")})
    }
}
#Preview {
    TaskListViewHelper(section: [secGraveyard], items: [TaskItem(), TaskItem()],taskSelector: {a,b,c in debugPrint("triggered")})
}
#endif

#if os(iOS)
struct TaskListViewHelper : View {
    @State var section: [TaskSection]
    @State var items: [TaskItem]
    
    var body: some View {
        TaskListView(section: section, items: items)
    }
}
#Preview {
    TaskListViewHelper(section: [secGraveyard], items: [TaskItem(), TaskItem()])
}
#endif
