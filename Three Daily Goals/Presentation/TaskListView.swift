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
    var body: some View {
        List {
            Section (header:
                        VStack(alignment: .leading) {
                            ForEach(section) { sec in
                                sec.asText
                            }
                        }) {
                ForEach(items) { item in
                    LinkToTask(item: item)
                }
            }
        }
        
    }
}

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

