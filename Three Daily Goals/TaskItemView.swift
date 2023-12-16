//
//  TaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI

struct TaskItemView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var item: TaskItem
    
    private func closeTask() {
        withAnimation {
            item.state = .closed
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            StateView(state: $item.state)
            LabeledContent{
                TextField("Title", text: $item.title)
                    .bold()
            } label: {
                Text("Title:").bold()
            }
            LabeledContent{
                TextField("Details", text: $item.details, axis: .vertical)
                    .textFieldStyle(.squareBorder)
            } label: {
                Text("Details:").bold()
            }
            HStack{
                LabeledContent{
                    Text(item.created, format: Date.FormatStyle(date: .numeric, time: .standard))
                } label: {
                    Text("Created:").bold()
                }
                LabeledContent{
                    Text(item.changed, format: Date.FormatStyle(date: .numeric, time: .standard))
                } label: {
                    Text("Last Changed:").bold()
                }
            }
        }.toolbar {
            ToolbarItem {
                Button(action: closeTask) {
                    Label("Close Task", systemImage: "xmark.circle.fill")
                }
            }
        }
        
    }
}

#Preview {
    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
}
