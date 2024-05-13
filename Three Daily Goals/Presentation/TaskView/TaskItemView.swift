//
//  TaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI
import TagKit

struct TDGShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content //.shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
            //.shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
    }
}
//
//extension TagCapsule {
//    init (text: String, style: TagCapsuleStyle) {
//        self.init(text)
//        self.tagCapsuleStyle(style)
//    }
//}

extension View {
    
    /// include parameter was necessary in order to prevent flooding of the same toolbar on all views when shown on an iPad
    var tdgShadow: some View {
        return self.modifier(TDGShadowModifier())
    }
}
struct InnerTaskItemView : View {
    let accentColor: Color
    @Bindable var item: TaskItem
    @FocusState var isTitleFocused: Bool
    let allTags: [String]
    @State var buildTag: String = ""
    let selectedTagStyle: TagCapsuleStyle
    let missingTagStyle: TagCapsuleStyle


    var body: some View {
        VStack(alignment: .leading){
            HStack {
                StateView(state: item.state, accentColor:  accentColor)
                Text("Task").font(.title).foregroundStyle(accentColor)
                Spacer()
            }
            
            LabeledContent{
                TextField("titleField", text: $item.title).accessibilityIdentifier("titleField").focused($isTitleFocused)
                    .bold().frame(idealHeight: 13)
            } label: {
                Text("Title:").bold().foregroundColor(Color.secondaryColor)
            }.tdgShadow
            
            //        Details
            LabeledContent{
                TextField("Details", text: $item.details, axis: .vertical)
#if os(macOS)
                    .textFieldStyle(.squareBorder)
#endif
                    .frame(idealHeight: 30).frame(minHeight: 30)
                    .tdgShadow
            } label: {
                Text("Details:").bold().foregroundColor(Color.secondaryColor)
            }
            
            //        URL
            LabeledContent{
                HStack{
                    TextField("URL", text: $item.url, axis: .vertical)
#if os(macOS)
                        .textFieldStyle(.squareBorder)
#endif
                        .frame(idealHeight: 30).frame(minHeight: 30).tdgShadow
                    if let link = URL(string: item.url) {
                        Link("Open",destination: link)
                    }
                }
            } label: {
                Text("URL:").bold().foregroundColor(Color.secondaryColor)
            }
            
            LabeledContent{
                DatePickerNullable(selected: $item.due, defaultDate: getDate(inDays: 7)).tdgShadow
            } label: {
                Text("Due Date:").bold().foregroundColor(Color.secondaryColor)
            }
            
            GroupBox {
                HStack {
                    Text("Add new Label:")
                    TagTextField(text:  $buildTag ,placeholder: "Tag Me") { newTag in
                        item.tags.append(newTag)
                    }
                }
                TagEditList(tags: $item.tags,additionalTags: allTags,container: .vstack) {text, isTag in
                    TagCapsule(text)
                        .tagCapsuleStyle(isTag ? selectedTagStyle : missingTagStyle)
                }
            }
            
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
    }
}

struct TaskItemView: View {
    @Bindable var model: TaskManagerViewModel
    @Bindable var item: TaskItem
@FocusState private var isTitleFocused: Bool
    
    var body: some View {
        InnerTaskItemView(accentColor: model.accentColor, item: item, allTags: model.activeTags.asArray, selectedTagStyle: model.selectedTagStyle, missingTagStyle: model.missingTagStyle )
        // .tdgToolbar(model: model, include : !isLargeDevice)
            .toolbar {
#if os(iOS)
                ToolbarItem{
                    model.undoButton
                }
                ToolbarItem{
                    model.redoButton
                }
#endif
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
                if item.canBeMovedToPendingResponse {
                    ToolbarItem {
                        model.waitForResponseButton(item: item)
                    }
                }
                if item.canBeTouched {
                    ToolbarItem {
                        model.touchButton(item: item)
                    }
                }
            }.onAppear(perform:{
                model.updateUndoRedoStatus()
                isTitleFocused = true
            })
    }
}

#Preview {
    //    TaskItemView(item: TaskItem()).frame(width: 600, height: 300)
    let model = dummyViewModel()
    
    
#if os(macOS)
    return TaskItemView( model: model , item: model.items.first()!).frame(width: 600, height: 600)
#endif
#if os(iOS)
    return TaskItemView( model: model , item: model.items.first()!)
#endif
}
