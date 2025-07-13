//
//  RegularMainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 10/02/2024.
//

import SwiftUI

struct RegularMainView: View {
    @Bindable var model: TaskManagerViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            LeftSideView(model: model).background(Color.background).frame(maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 300, ideal: 450)
                .mainToolbar(model: model)
        } content: {
            SingleView {
                ListView(model: model).background(Color.background)
            }.background(Color.background)
                .navigationSplitViewColumnWidth(min: 250, ideal: 400)
                .navigationTitle("Three Daily Goals")
                #if os(macOS)
                    .navigationSubtitle(model.streakView())
                #endif
        } detail: {
            if let detail = model.selectedItem {
                TaskItemView(model: model, item: detail).frame(minWidth: 300)
            } else {
                Text("Select an item").frame(minWidth: 300)
            }
        }.navigationSplitViewStyle(.balanced)
            .standardToolbar(model: model)
    }
}

#Preview {
    RegularMainView(model: dummyViewModel())
}
