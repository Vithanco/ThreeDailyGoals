//
//  ReviewNextPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewNextPriorities: View {
    
    @Bindable var model: TaskManagerViewModel
    
    @State private var presentAlert = false
    @State private var newTaskName: String = ""
    
    var body: some View {
        VStack{
#if os(macOS)
            
            Text("Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                ListView(whichList: .priority, model: model).frame(minHeight: 300)
                ListView(whichList: .open ,model: model)
            }
            
#endif
#if os(iOS)  // delete this once iOS works as expected and keep macOS path for all
            Text("Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                VStack{
                    HStack {
                        Spacer()
                        Circle().frame(width: 10).foregroundColor(.accentColor).help("Drop Target because iOS has an issue. Will be hopefully removed with next version of iOS.")
                        Spacer()
                    }.dropDestination(for: String.self){
                        items, location in
                        for item in items.compactMap({
                            model.findTask(withID: $0)}) {
                            model.move(task: item, to: .priority)
                        }
                        return true
                    }
                    ListView(whichList: .priority, model: model.taskModel).frame(minHeight: 300)
                }
                VStack{
                    HStack {
                        Spacer()
                        Circle().frame(width: 10).foregroundColor(.accentColor).help("Drop Target, as iOS has an issue. Will be hopefully removed with next version of iOS.")
                        Spacer()
                    }.dropDestination(for: String.self){
                        items, location in
                        for item in items.compactMap({
                            model.taskModel.findTask(withID: $0)}) {
                            model.taskModel.move(task: item, to: .open)
                        }
                        return true
                    }
                    ListView(whichList: .open ,model: model)
                }
            }
            
#endif
            Button(action: { presentAlert = true}) {
                Label("Add Task", systemImage: imgAddItem).help("Add new task to list of open tasks.")
            }
        }.frame(minHeight: 300,idealHeight: 800, maxHeight: .infinity)
        .alert("Quick Add", isPresented: $presentAlert, actions: {
            TextField("task title", text: $newTaskName)
            
            Button("Cancel", role: .cancel, action: {presentAlert = false})
            Button("Add Task", action: {
                presentAlert = false
                model.addItem(title: newTaskName)
            })
        }, message: {
            Text("Please enter new task name")
        })
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfReview = .review
    return ReviewNextPriorities(model: model)
}
