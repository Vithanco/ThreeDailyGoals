//
//  RegularMainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 10/02/2024.
//

import SwiftUI

struct CompactMainView: View {
    @Environment(TaskManagerViewModel.self) private var model

    var body: some View {
        @Bindable var model = model
        return NavigationStack {
            LeftSideView().background(Color.background)
                .navigationDestination(isPresented: $model.uiState.showItem) {
                    if let item = model.uiState.selectedItem {
                        TaskItemView(item: item)
                    }
                }
                .mainToolbar()
                .toolbar {
                    ToolbarItem {
                        model.addNewItemButton
                    }
                }
        }.frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity /*@END_MENU_TOKEN@*/)

    }
}
#Preview {
    CompactMainView()
        .environment(dummyViewModel())
}
