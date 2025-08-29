//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI

extension TaskSection {
    var asText: Text {
        return Text(text).font(.title)
    }
}

struct StateView: View {
    let state: TaskItemState

    var body: some View {
        state.section.asText.foregroundStyle(state.color)
    }
}
