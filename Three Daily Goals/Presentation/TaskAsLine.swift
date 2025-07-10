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
    
    var text: some View {
        return Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines))
            .strikethrough( item.isClosed, color: accentColor)
            .draggable(item.id)
    }
    
    var hasDue: Bool {
        return item.due != nil && item.isOpenOrPriority
    }
    

    
    var body: some View {
        HStack{

            text
            Spacer()
            if hasDue {
                Text(item.due!.timeRemaining).italic().foregroundStyle(Color.gray)
            }
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
            if item.canBeMadePriority {
                model.priorityButton(item: item)
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
