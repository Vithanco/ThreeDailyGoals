//
//  RegularMainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 10/02/2024.
//

import SwiftUI

struct CompactMainView: View {
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        NavigationStack{
            LeftSideView(model: model).background(Color.background)
                .navigationDestination(isPresented: $model.showItem) {
                    if let item = model.selectedItem {
                        TaskItemView(model:model, item: item)
                    }
                }
        }.frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
    }
}
#Preview {
    CompactMainView(model: dummyViewModel())
}
