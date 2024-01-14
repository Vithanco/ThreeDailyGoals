//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI


struct StateView: View {
    let state: TaskItemState
    
    var body: some View {
        state.sections.first()?.asText
    }
}


struct StateViewHelper : View {
    @State var state: TaskItemState
    var body: some View {
        StateView(state: state)
    }
}
#Preview {
    Group {
        StateViewHelper(state: TaskItemState.open)
        StateViewHelper(state: TaskItemState.closed)
        StateViewHelper(state: TaskItemState.dead)
        StateViewHelper(state: TaskItemState.pendingResponse)
        StateViewHelper(state: TaskItemState.priority)
    }
        
}
