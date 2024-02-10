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
        NavigationSplitView (columnVisibility: $columnVisibility){
            LeftSideView(model: model).background(Color.background).frame(maxHeight: .infinity)
                .navigationDestination(isPresented: $model.showItem) {
                    if let item = model.selectedItem {
                        TaskItemView(model:model, item: item)
                    }
                }
                .navigationSplitViewColumnWidth(min: 300, ideal: 400)
        } content: {
            SingleView{
                ListView( model: model).background(Color.background)
            }.background(Color.background)
                .navigationSplitViewColumnWidth(min: 250, ideal: 400)
                .navigationTitle("Three Daily Goals")
#if os(macOS)
                .navigationSubtitle(
                    streakView(model: model))
#endif
        }
    detail: {
        if let detail = model.selectedItem {
            TaskItemView(model: model, item: detail)
        } else {
            Text("Select an item")
        }
    }.navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    RegularMainView(model: dummyViewModel())
}
