//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftData
import SwiftUI

private struct ListLabel: View {
    let whichList: TaskItemState
    @Bindable var model: TaskManagerViewModel

    var name: Text {
        return whichList.section.asText
    }

    var count: Text {
        return Text(model.list(which: whichList).count.description)
    }

    var body: some View {
        HStack {
            name
            Spacer()
            if whichList.showCount {
                count
            }
        }.accessibilityIdentifier(whichList.getLinkedListAccessibilityIdentifier)
            .dropDestination(for: String.self) {
                items, location in
                for item in items.compactMap({ model.findTask(withUuidString: $0) }) {
                    model.move(task: item, to: whichList)
                }
                return true
            }
            .foregroundStyle(model.accentColor)
            .frame(maxWidth: .infinity)
    }
}

struct LinkToList: View {
    @State var whichList: TaskItemState
    @Bindable var model: TaskManagerViewModel

    var body: some View {
        SingleView {
            if isLargeDevice {
                ListLabel(whichList: whichList, model: model)
                    .onTapGesture {
                        model.select(which: whichList, item: model.list(which: whichList).first)
                    }
            } else {
                NavigationLink {
                    ListView(whichList: whichList, model: model)
                        .standardToolbar(model: model, include: !isLargeDevice)
                } label: {
                    ListLabel(whichList: whichList, model: model)
                        .foregroundStyle(model.accentColor)
                }
            }
        }
    }
}

#Preview {
    LinkToList(whichList: .open, model: dummyViewModel())
}
