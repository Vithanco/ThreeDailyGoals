//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct TaskListView: View {
    let section: [TaskSection]
    let items: [TaskItem]
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

#Preview {
    TaskListView(section: [secGraveyard], items: [TaskItem(), TaskItem()])
}
