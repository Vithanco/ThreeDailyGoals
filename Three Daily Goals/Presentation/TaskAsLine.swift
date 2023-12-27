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
        }
        
    }
}


struct TaskAsLine: View {
    let item: TaskItem
    
    func action () {
        if item.isClosed {
            item.state = .open
        } else {
            item.state = .closed
        }
    }
    
    var body: some View {
        HStack {
            Checkbox(isChecked: item.isClosed, action: action).background(Color.backgroundColor)
            Text(item.title).background(Color.backgroundColor)
        }.background(Color.backgroundColor)
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
