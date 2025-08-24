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
        NavigationStack {
            LeftSideView().background(Color.background)
                .navigationDestination(isPresented: Binding(
                    get: { model.showItem },
                    set: { model.showItem = $0 }
                )) {
                    if let item = model.selectedItem {
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
