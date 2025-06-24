//
//  ReviewCurrentPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckCurrentPriorities: View {
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        VStack{
            Text("Current Priority Tasks").font(.title2).foregroundStyle(model.accentColor).padding(5)
            Text("Slide tasks to the left to close them." )
            Text("All non-closed tasks will be moved to open list. You can re-prioritise them later.")
            ListView(whichList: .priority, model: model)
        }.frame(minHeight: 300, idealHeight: 500)
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfCompassCheck = .currentPriorities
    return CompassCheckCurrentPriorities(model: model)
}
