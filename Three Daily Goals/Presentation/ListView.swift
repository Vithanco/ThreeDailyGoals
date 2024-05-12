//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import TagKit


extension ListHeader {
    var asText: Text {
        Text("Last updated: " + self.name).font(.callout)
    }
}


struct ListView: View {
    @State var whichList: TaskItemState?
    @Bindable var model: TaskManagerViewModel
    @State var selectedTags: [String]
    @State var allTags: [String]
    
    init(whichList: TaskItemState? = nil, model: TaskManagerViewModel) {
        self.whichList = whichList
        self.model = model
        self.selectedTags = []
        self.allTags = model.list(which: whichList ?? model.whichList).tags.asArray
    }
    
    var list: TaskItemState {
        return whichList ?? model.whichList
    }
    
    var body: some View {
        let filterFunc : (TaskItem) -> Bool = selectedTags.isEmpty ? {_ in return true} : {$0.tags.contains(selectedTags)}
        let itemList = model.list(which: list).filter(filterFunc)
        let headers = list.subHeaders
//        let partialLists : [[TaskItem]] = headers.map({$0.filter(items: itemList)})
        
        TagEditList(tags: $selectedTags, additionalTags: allTags, container: .vstack,
                tagView: {text, isSelected in
            TagCapsule(text)
                .tagCapsuleStyle(isSelected ? model.selectedTagStyle : model.missingTagStyle)})
        
        SimpleListView(itemList: itemList, headers: headers, showHeaders: list != .priority, section: list.section, id: list.getListAccessibilityIdentifier, model: model)
            .frame(minHeight: 145, maxHeight: .infinity)
            .background(Color.background)
#if os(iOS)
            .toolbar{
                ToolbarItem{
                    model.undoButton
                }
                ToolbarItem{
                    model.redoButton
                }
            }
#endif
            .dropDestination(for: String.self){
                items, location in
                for item in items.compactMap({model.findTask(withID: $0)}) {
                    model.move(task: item, to: list)
                }
                return true
            }
        
    }
}

#Preview {
    ListView( model: dummyViewModel())
}
