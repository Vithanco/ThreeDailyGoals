//
//  TaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI


struct TaskItemView: View {
    @Bindable var model: TaskManagerViewModel
    @Bindable var item: TaskItem
    
    private func undo() {
        model.undo()
    }
    
    private func redo() {
        model.redo()
    }
    
    private func updateUndoRedoStatus() {
        model.updateUndoRedoStatus()
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                StateView(state: item.state, accentColor:  model.accentColor)
                Text("Task").font(.title).foregroundStyle(model.accentColor)
                Spacer()

            }
        }
        LabeledContent{
            TextField("Title", text: $item.title)
                .bold().frame(idealHeight: 13)
        } label: {
            Text("Title:").bold().foregroundColor(Color.secondaryColor)
        }.shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
            .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
        
//        Details
        LabeledContent{
            TextField("Details", text: $item.details, axis: .vertical)
#if os(macOS)
                .textFieldStyle(.squareBorder)
#endif
                .frame(idealHeight: 30).frame(minHeight: 30)
        } label: {
            Text("Details:").bold().foregroundColor(Color.secondaryColor)
        }.shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
            .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
        
//        URL
        LabeledContent{
            HStack{
                TextField("URL", text: $item.url, axis: .vertical)
#if os(macOS)
                    .textFieldStyle(.squareBorder)
#endif
                    .frame(idealHeight: 30).frame(minHeight: 30)
                if let link = URL(string: item.url) {
                    Link("Open",destination: link)
                }
            }
        } label: {
                Text("URL:").bold().foregroundColor(Color.secondaryColor)
        }.shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
            .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
        
        if let comments = item.comments, comments.count > 0 {
            VStack (alignment: .leading){
                Text("History:").bold().foregroundColor(Color.secondaryColor)
                ForEach(comments.sorted()){comment in
                    CommentView(comment: comment).frame(maxWidth: .infinity)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        Spacer()
        HStack{
            LabeledContent{
                Text(item.created, format: stdDateFormat)
            } label: {
                Text("Created:").bold().foregroundColor(Color.secondaryColor)
            }
            LabeledContent{
                Text(item.changed, format: stdDateFormat)
            } label: {
                Text("Last Changed:").bold().foregroundColor(Color.secondaryColor)
            }
        }.background(Color.background).padding()
#if os(iOS)
            .tdgToolbar(model: model)
#endif
            .toolbar {
                ToolbarItem {
                    Button(action:  {
                        if item.state == .priority{
                            model.move(task: item, to: .open)
                        } else {
                            model.move(task: item, to: .priority)
                        }
                    }) {
                        Label("Toggle Priority", systemImage: imgToday).help("Add to/ remove from today's priorities")
                    }
                }
                if item.isOpen || item.isPriority {
                    ToolbarItem {
                        Button(action: {
                            item.closeTask()
                        }) {
                            Label("Close", systemImage: imgCloseTask).help("Close")
                        }
                    }
                } else {
                    ToolbarItem {
                        Button(action: {
                            item.reOpenTask()
                        }) {
                            Label("Reopen", systemImage: imgReopenTask).help("Reopen")
                        }
                    }
                }
                ToolbarItem {
                    Button(action: {
                        item.touch()
                    }) {
                        Label("Touch", systemImage: imgTouch).help("'Touch' the task - when you did something with it.")
                    }
                }
            }.onAppear(perform:{updateUndoRedoStatus()})
    }
}

#Preview {
//    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
    TaskItemView( model: dummyViewModel(), item: TaskItem()).frame(width: 600, height: 300)
}
