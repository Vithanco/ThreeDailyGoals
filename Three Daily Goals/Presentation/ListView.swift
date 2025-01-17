//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import TagKit

extension ListHeader {
    var asText : Text {
        Text("Last updated: \(name)"  ).font(.callout)
    }
}

struct ListView: View {
    @State var whichList: TaskItemState?
    @Bindable var model: TaskManagerViewModel

    init(whichList: TaskItemState? = nil, model: TaskManagerViewModel) {
        self.whichList = whichList
        self.model = model
    }

    var list: TaskItemState {
        return whichList ?? model.whichList
    }

    var body: some View {
        let filterFunc: (TaskItem) -> Bool = model.selectedTags.isEmpty ? { _ in true } : { $0.tags.contains(where: model.selectedTags.contains) }
        let itemList = model.list(which: list).filter(filterFunc)
        let headers = list.subHeaders
//        let partialLists : [[TaskItem]] = headers.map({$0.filter(items: itemList)})
        VStack {
            TagEditList(tags: $model.selectedTags,
                        additionalTags: model.list(which: whichList ?? model.whichList).tags.asArray,
                        container: .vstack,
                        horizontalSpacing: 1,
                        verticalSpacing: 1,
                        tagView: { text, isSelected in
                            TagCapsule(text)
                                .tagCapsuleStyle(isSelected ? model.selectedTagStyle : model.missingTagStyle)
                        }).padding(2).frame(maxHeight: 30)

            SimpleListView(itemList: itemList, headers: headers, showHeaders: list != .priority, section: list.section, id: list.getListAccessibilityIdentifier, model: model)
                .frame(minHeight: 145, maxHeight: .infinity)
                .background(Color.background)
#if os(iOS)
                .toolbar {
                    ToolbarItem {
                        model.undoButton
                    }
                    ToolbarItem {
                        model.redoButton
                    }
                }
#endif
                .dropDestination(for: String.self) {
                    items, _ in
                    for item in items.compactMap({ model.findTask(withUuidString: $0) }) {
                        model.move(task: item, to: list)
                    }
                    return true
                }
        }.background(Color.white)
    }
}

#Preview {
    ListView(whichList: .dead, model: dummyViewModel())
}
