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
    var body: some View {
        NavigationLink {
            TaskItemView(model: model, item: item)
        } label: {
            TaskAsLine(item: item)
        }
    }
}

//#Preview {
//    LinkToTask(item: TaskItem())
//}
