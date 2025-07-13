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
        Text("Last updated: \(name)").font(.callout)
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
        return whichList ?? (model.whichList == .priority ? .open : model.whichList)
    }

    var body: some View {
        let filterFunc: (TaskItem) -> Bool =
            model.selectedTags.isEmpty
            ? { _ in true } : { $0.tags.contains(where: model.selectedTags.contains) }
        let itemList = model.list(which: list).filter(filterFunc)
        let headers = list.subHeaders
        VStack {
            SimpleListView(
                itemList: itemList, headers: headers, showHeaders: list != .priority, section: list.section,
                id: list.getListAccessibilityIdentifier, model: model
            )
            .frame(minHeight: 145, maxHeight: .infinity)
            .background(Color.background)
            .dropDestination(for: String.self) {
                items, _ in
                for item in items.compactMap({ model.findTask(withUuidString: $0) }) {
                    model.move(task: item, to: list)
                }
                return true
            }
            Spacer()
            let tags = model.list(which: whichList ?? model.whichList).tags.asArray
            if !tags.isEmpty {
                TagEditList(
                    tags: $model.selectedTags,
                    additionalTags: tags,
                    container: .vstack,
                    horizontalSpacing: 1,
                    verticalSpacing: 1,
                    tagView: { text, isSelected in
                        TagCapsule(text)
                            .tagCapsuleStyle(isSelected ? model.selectedTagStyle : model.missingTagStyle)
                    }
                ).frame(maxWidth: 300, idealHeight: 15, maxHeight: 50).background(Color.background).padding(
                    5)
            }

        }
    }
}

#Preview {
    ListView(whichList: .dead, model: dummyViewModel())
}
