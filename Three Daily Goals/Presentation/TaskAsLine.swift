//
//  TaskAsLine.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 24/12/2023.
//

import SwiftUI



struct Checkbox : View {
    
    typealias OnCheckboxClick = () -> Void
    
    let isChecked: Bool
    let action: OnCheckboxClick
    
    var body: some View {
        Button(action: action){
            Image(systemName: isChecked ? imgCheckedBox : imgUncheckedBox)
        }.background(Color.background)
        
    }
}


struct TaskAsLine: View {
    let item: TaskItem
    
    func action () {
        if item.isClosed {
            item.reOpenTask()
        } else {
            item.closeTask()
        }
    }
    
    var body: some View {
        HStack {
            Checkbox(isChecked: item.isClosed, action: action).frame(maxWidth: 30)
            Text(item.title).strikethrough( item.isClosed, color: Color.mainColor).draggable(item.id)
        }
    }
}


struct TaskAsLineHelper : View {
    @State var item: TaskItem = TaskItem()
    
    var body: some View {
        TaskAsLine(item: item)
    }
}

#Preview {
    TaskAsLineHelper()
}
