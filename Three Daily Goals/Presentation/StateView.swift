//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI



extension TaskSection {
    var asText: Text {
        return Text("\(Image(systemName: image)) \(text)").font(.title)
    }
}

struct StateView: View {
    let state: TaskItemState
    let accentColor : Color
    
    var body: some View {
        state.section.asText.foregroundStyle(accentColor)
    }
}

#Preview {
    Group {
        StateView(state: TaskItemState.open, accentColor: Color.red)
        StateView(state: TaskItemState.closed, accentColor: Color.red)
        StateView(state: TaskItemState.dead, accentColor: Color.red)
        StateView(state: TaskItemState.pendingResponse, accentColor: Color.red)
        StateView(state: TaskItemState.priority, accentColor: Color.red)
    }
        
}
