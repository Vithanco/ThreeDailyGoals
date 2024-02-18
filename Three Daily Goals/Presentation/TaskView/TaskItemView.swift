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
    @FocusState private var isTitleFocused: Bool
    
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
            
            LabeledContent{
                TextField("titleField", text: $item.title).accessibilityIdentifier("titleField").focused($isTitleFocused)
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
            
            Spacer()
            AllCommentsView(item: item).frame(maxWidth: .infinity, maxHeight: 200)
            
            HStack{
                LabeledContent{
                    Text(item.created, format: stdOnlyDateFormat)
                } label: {
                    Text("Created:").bold().foregroundColor(Color.secondaryColor)
                }
                LabeledContent{
                    Text(item.changed.timeAgoDisplay())
                } label: {
                    Text("Changed:").bold().foregroundColor(Color.secondaryColor)
                }
            }
        }.background(Color.background).padding()
            .tdgToolbar(model: model, include : !isLargeDevice)
            .toolbar {
                ToolbarItem {
                    model.toggleButton(item: item)
                }
                if item.canBeClosed {
                    ToolbarItem {
                        model.closeButton(item: item)
                    }
                }
                if item.canBeMovedToOpen {
                    ToolbarItem {
                        model.openButton(item: item)
                    }
                }
                if item.canBeTouched {
                    ToolbarItem {
                        model.touchButton(item: item)
                    }
                }
            }.onAppear(perform:{
                updateUndoRedoStatus()
                isTitleFocused = true
            })
    }
}

#Preview {
    //    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
    let model = dummyViewModel()
    return TaskItemView( model: model , item: model.items.first()!).frame(width: 600, height: 300)
}
