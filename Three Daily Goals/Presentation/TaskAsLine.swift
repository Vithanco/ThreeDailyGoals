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
    
    var text: String {
        var result = item.title
        if let due = item.due, item.isOpenOrPriority {
            result += "\n\(due.timeRemaining)"
        }
        return result
    }
    
    var body: some View {
        HStack{
            Text(text).strikethrough( item.isClosed, color: accentColor)
                .draggable(item.id)
            Spacer()
        }
        .draggable(item.id)
        .swipeActions {
            if item.canBeMovedToPendingResponse {
                model.waitForResponseButton(item: item)
            }
            if item.canBeMovedToOpen {
                model.openButton(item: item)
            }
            if item.canBeDeleted{
                model.deleteButton(item: item)
            }
            if item.canBeClosed {
                model.killButton(item: item)
                model.closeButton(item: item)
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
