//
//  LinkToTask.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import SwiftUI

struct LinkToTask: View {
    let item: TaskItem
    var body: some View {
        NavigationLink {
            TaskItemView(item: item)
        } label: {
            Text(item.title)
        }
    }
}

#Preview {
    LinkToTask(item: TaskItem())
}
