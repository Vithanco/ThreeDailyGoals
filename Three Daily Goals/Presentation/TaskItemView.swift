//
//  TaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI


struct TaskItemView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var today : DailyTasks
    @Bindable var item: TaskItem
    
    @State private var canUndo = false
    @State private var canRedo = false
    
    private func undo() {
        modelContext.undoManager?.undo()
        updateUndoRedoStatus()
    }
    
    private func redo() {
        modelContext.undoManager?.redo()
        updateUndoRedoStatus()
    }
    
    private func updateUndoRedoStatus() {
        canUndo =  modelContext.undoManager?.canUndo ?? false
        canRedo =  modelContext.undoManager?.canRedo ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                StateView(state: $item.state)
                Text("Task").font(.title).foregroundStyle(Color.mainColor)
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
        }.background(Color.backgroundColor).padding()
            .toolbar {
#if os(iOS)
                ToolbarItem {
                    Button(action: undo) {
                        Label("Undo", systemImage: imgUndo)
                    }.disabled(!canUndo)
                }
                ToolbarItem {
                    Button(action: redo) {
                        Label("Redo", systemImage: imgRedo)
                    }.disabled(!canRedo)
                }
#endif
                ToolbarItem {
                    Button(action: {
                        item.makePriority(position: today.priorities?.count ?? 0, day: today)
                    }) {
                        Label("Make a Priority", systemImage: imgToday).help("Add to today's priorities")
                    }
                }
                if item.isOpen {
                    ToolbarItem {
                        Button(action: {
                            item.closeTask()
                        }) {
                            Label("Close", systemImage: imgCloseTask).help("Close")
                        }
                    }
                }
                if item.isClosed {
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
    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
}
