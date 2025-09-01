//
//  ReviewPendingResponses.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckDueDate: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager

    var body: some View {
        VStack {
            Text("These Tasks are close to their due Dates. They will now be moved to Priority").font(
                .title2
            ).foregroundStyle(Color.priority)
            Spacer()
            Text(
                "Swipe left in order to close them, or move them back to Open Tasks (you can prioritise them in the next step)."
            )
            SimpleListView(
                color: Color.dueSoon,
                itemList: compassCheckManager.dueDateSoon, headers: [ListHeader.all], showHeaders: false,
                section: secDueSoon, id: "dueSoonList")
        }.frame(minHeight: 300, idealHeight: 800, maxHeight: .infinity)
    }
}

//#Preview {
//    CompassCheckDueDate()
//        .environment(dummyViewModel())
//}
