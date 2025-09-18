//
//  LinkToTask.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import SwiftUI

import tdgCoreMain

struct LinkToTask: View {
    @Environment(UIStateManager.self) private var uiState
    @Bindable var item: TaskItem
    let list: TaskItemState

    var body: some View {
        if isLargeDevice {
            Button(action: {
                uiState.select(which: list, item: item)
            }) {
                TaskAsLine(item: item)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("linkToTask" + item.title)
        } else {
            ZStack {
                TaskAsLine(item: item)
                    .accessibilityIdentifier(item.id.description)
                NavigationLink(destination: TaskItemView(item: item)) {
                    EmptyView()
                }
                .opacity(0)
                .accessibilityHidden(true)
            }
        }
    }
}

//#Preview {
//
//    LinkToTask(item: model.dataManager.items.first ?? TaskItem(), list: .open)
//        .environment(UIStateManager.testManager())
//        .environment(DataManager.testManager())
//        .environment(dummyPreferences())
//}
