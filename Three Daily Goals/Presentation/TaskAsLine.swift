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
                model.openButton(item: item)
            }
            if item.canBeDeleted{
                model.deleteButton(item: item)
            }
            if item.canBeClosed {
                model.closeButton(item: item)
                model.killButton(item: item)
            }
        }
        
    }
}


//struct TaskAsLineHelper : View {
//    @State var
//    
//    var body: some View {
//        TaskAsLine(item: model.items.first!, model: model)
//    }
//}

#Preview {
    let model: TaskManagerViewModel = dummyViewModel()
    return TaskAsLine(item: model.items.first!, model: model)
}
