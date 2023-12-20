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
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                StateView(state: $item.state)
                Text("Task").font(.title).foregroundStyle(mainColor)
                Spacer()

            }
        }
        LabeledContent{
            TextField("Title", text: $item.title)
                .bold().frame(idealHeight: 13)
        } label: {
            Text("Title:").bold().foregroundColor(secondaryColor)
        }
        LabeledContent{
            TextField("Details", text: $item.details, axis: .vertical)
#if os(macOS)
                .textFieldStyle(.squareBorder)
#endif
                .frame(idealHeight: 30).frame(minHeight: 30)
        } label: {
            Text("Details:").bold().foregroundColor(secondaryColor)
        }
        
        if let comments = item.comments, comments.count > 0 {
            
            LabeledContent{
                VStack {
                    ForEach(comments){comment in
                        CommentView(comment: comment)
                    }
                }
            } label: {
                Text("History:").bold().foregroundColor(secondaryColor)
            }
            
        }
        Spacer()
        HStack{
            LabeledContent{
                Text(item.created, format: stdDateFormat)
            } label: {
                Text("Created:").bold().foregroundColor(secondaryColor)
            }
            LabeledContent{
                Text(item.changed, format: stdDateFormat)
            } label: {
                Text("Last Changed:").bold().foregroundColor(secondaryColor)
            }
        }.background(.white).padding()
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        item.makePriority(position: 1, day: today)
                    }) {
                        Label("", systemImage: imgPriority1)
                    }
                }
                ToolbarItem {
                    Button(action: {
                        item.makePriority(position: 2, day: today)
                    }) {
                        Label("", systemImage: imgPriority2)
                    }
                }
                ToolbarItem {
                    Button(action: {
                        item.makePriority(position: 3, day: today)
                    }) {
                        Label("", systemImage: imgPriority3)
                    }
                }
                ToolbarItem {
                    Button(action: {
                        item.makePriority(position: 4, day: today)
                    }) {
                        Label("", systemImage: imgPriorityX)
                    }
                }
                if item.isOpen {
                    ToolbarItem {
                        Button(action: {
                            item.closeTask()
                        }) {
                            Label("", systemImage: imgCloseTask)
                        }
                    }
                }
                if item.isClosed {
                    ToolbarItem {
                        Button(action: {
                            item.reOpenTask()
                        }) {
                            Label("", systemImage: imgReopenTask)
                        }
                    }
                }
                if item.isGraveyarded {
                    ToolbarItem {
                        Button(action: {
                            item.touch()
                        }) {
                            Label("", systemImage: imgTouch)
                        }
                    }
                }

            }
        
    }
    
}

#Preview {
    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
}
