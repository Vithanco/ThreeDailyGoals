//
//  ReviewPendingResponses.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewDueDate: View {
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        VStack{
            Text("These Tasks are close to their due Dates. They will now be moved to Priority").font(.title2).foregroundStyle(model.accentColor)
            Spacer()
            Text("Swipe left in order to close them, or move them back to Open Tasks (you can prioritise them in the next step).")
            SimpleListView(itemList: model.dueDateSoon, headers: [all], showHeaders: false, section: secDueSoon, id: "dueSoonList", model: model)
        }.frame(minHeight: 300, idealHeight: 800, maxHeight:.infinity )
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfReview = .dueDate
    return ReviewDueDate(model: model)
}
