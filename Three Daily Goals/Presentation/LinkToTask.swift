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
        if isLargeDevice {
            TaskAsLine(item: item, model: model).onTapGesture {
                model.select(which: list, item: item)
            }.accessibilityIdentifier("linkToTask" + item.title)
        } else {
            HStack {
                NavigationLink {
                    TaskItemView(model: model, item: item)
                } label: {
                    TaskAsLine(item: item, model: model).accessibilityIdentifier(item.id.description)
                }
            }
        }
    }
}

#Preview {
    //@Previewable
    @State var model = dummyViewModel()

    return LinkToTask(model: model, item: model.items.first ?? TaskItem(), list: .open)
}
