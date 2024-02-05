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
    @Bindable var model: TaskManagerViewModel
    
    func action () {
        if item.isClosed || item.isGraveyarded {
            model.move(task: item, to: .open)
        } else {
            model.move(task: item, to: .closed)
        }
    }
    
    var accentColor: Color {
        return model.accentColor
    }
    
    var body: some View {
        HStack {
            Checkbox(isChecked: item.isClosed, action: action).frame(maxWidth: 30)
            Text(item.title).strikethrough( item.isClosed, color: accentColor).draggable(item.id)
            if item.isPending {
                Spacer()
                Button(action: {model.move(task: item, to: .open)}, label: {return Text("move to \(Image(systemName: imgOpen))")})
            }
            if item.isClosed || item.isGraveyarded {
                Spacer()
                Button(role: .destructive, action: {model.delete(task: item)}, label: {return Text("delete").padding(0)}).foregroundColor(.white)
                    .padding(2)
                    .background(Color.red) // Red background to indicate a destructive action
                    .cornerRadius(8)
            }
        }
    }
}


struct TaskAsLineHelper : View {
    @State var item: TaskItem = TaskItem()
    @State var model: TaskManagerViewModel = dummyViewModel()
    
    var body: some View {
        TaskAsLine(item: item, model: model)
    }
}

#Preview {
    TaskAsLineHelper()
}
