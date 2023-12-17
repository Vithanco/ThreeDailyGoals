//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI

let mainColor = Color(red: 234.0/255.0, green: 88.0/255.0, blue: 12.0/255.0, opacity: 1.0)

struct StateView: View {
    @Binding var state: TaskItemState
    var body: some View {
        switch state {
            case .open: Text("\(Image(systemName: "figure.walk.circle.fill")) Open").font(.title).foregroundStyle(mainColor)
            case .closed: Text("\(Image(systemName: "flag.checkered.2.crossed")) Closed").font(.title).foregroundStyle(mainColor)
            case .graveyard: Text("\(Image(systemName: "heart.slash.fill")) Graveyard").font(.title).foregroundStyle(mainColor)
        }
    }
}


struct StateViewHelper : View {
    @State var state: TaskItemState
    var body: some View {
        StateView(state: $state)
    }
}
#Preview {
    Group {
        StateViewHelper(state: TaskItemState.open)
        StateViewHelper(state: TaskItemState.closed)
        StateViewHelper(state: TaskItemState.graveyard)
    }
        
}
