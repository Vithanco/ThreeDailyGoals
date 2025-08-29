//
//  RegularMainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 10/02/2024.
//

import SwiftUI

struct RegularMainView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(UIStateManager.self) private var uiState
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            LeftSideView().background(Color.background).frame(maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 300, ideal: 450)
                .mainToolbar()
        } content: {
            SingleView {
                ListView().background(Color.background)
            }.background(Color.background)
                .navigationSplitViewColumnWidth(min: 400, ideal: 600)
                .navigationTitle("Three Daily Goals")
        } detail: {
            if let detail = uiState.selectedItem {
                TaskItemView(item: detail).frame(minWidth: 300)
            } else {
                Text("Select an item").frame(minWidth: 300)
            }
        }.navigationSplitViewStyle(.balanced)
            .standardToolbar()
    }
}

//#Preview {
//    RegularMainView()
//        .environment(dummyViewModel())
//}
