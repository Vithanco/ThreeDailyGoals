//
//  ReviewPendingResponses.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckPendingResponses: View {
    @Environment(CloudPreferences.self) private var preferences

    var body: some View {
        VStack {
            Text("Can you close some tasks you wait on?").font(.title2).foregroundStyle(preferences.accentColor)
            Spacer()
            Text(
                "Swipe left in order to close them, or move them back to Open Tasks (you can prioritise them in the next step)."
            )
            ListView(whichList: .pendingResponse)
        }.frame(minHeight: 300, idealHeight: 800, maxHeight: .infinity)
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfCompassCheck = .pending
    return CompassCheckPendingResponses()
        .environment(model)
        .environment(dummyPreferences())
}
