//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI

public extension TaskSection {
    var asText: Text {
        return Text(text).font(.title)
    }
}

public struct StateView: View {
    public let state: TaskItemState

    public var body: some View {
        state.section.asText.foregroundStyle(state.color)
    }
}
