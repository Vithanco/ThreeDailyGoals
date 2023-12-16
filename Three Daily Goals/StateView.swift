//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI

struct StateView: View {
    @Binding var state: TaskItemState
    var body: some View {
        switch state {
            case .closed: Label("closed", systemImage: "circle.circle.fill")
            case .open: Label("open", systemImage: "circle")
            case .graveyard: Label("open", systemImage: "heart.slash.fill")
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
