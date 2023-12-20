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
    var taskSelector: TaskSelector
    var body: some View {
        List {
            Section (header:
                        VStack(alignment: .leading) {
                            ForEach(section) { sec in
                                sec.asText
                            }
                        }) {
                ForEach(items) { item in
                    Text(item.title).onTapGesture {
                        taskSelector(section,items,item)
                    }
                }
            }
        }
        
    }
}

struct TaskListViewHelper : View {
    @State var section: [TaskSection]
    @State var items: [TaskItem]
    
    var body: some View {
        TaskListView(section: section, items: items, taskSelector: {a, b, c in debugPrint("triggered")})
    }
}

#Preview {
    TaskListViewHelper(section: [secGraveyard], items: [TaskItem(), TaskItem()])
}

