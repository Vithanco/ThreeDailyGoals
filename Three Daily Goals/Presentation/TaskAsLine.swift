//
//  TaskAsLine.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 24/12/2023.
//

import SwiftUI

struct TaskAsLine: View {
    let item: TaskItem
    @Bindable var model: TaskManagerViewModel

    var accentColor: Color {
        return model.accentColor
    }
    
    var body: some View {
        HStack{
            Text(item.title).strikethrough( item.isClosed, color: accentColor)
                .draggable(item.id)
            Spacer()
        }
        .draggable(item.id)
        .swipeActions {
            if item.canBeMovedToOpen {
                Button{ model.move(task: item, to: .open) } label: {
                    Label("Move to open", systemImage: TaskItemState.open.imageName).help("Move to open")
                }
            }
            if item.canBeDeleted{
                Button(role: .destructive) { model.delete(task: item) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            if item.canBeClosed {
                Button{ model.move(task: item, to: .closed) } label: {
                    Label("Close Task", systemImage: TaskItemState.closed.imageName)
                }
            }
        }
        
    }
}


struct TaskAsLineHelper : View {
    @State var model: TaskManagerViewModel = dummyViewModel()
    
    var body: some View {
        TaskAsLine(item: model.items.first!, model: model)
    }
}

#Preview {
    TaskAsLineHelper()
}
