//
//  ReviewDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CompassCheckDialog: View {

    @Bindable var model: TaskManagerViewModel
    //    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        VStack {

            HStack {
                Text("Daily Compass Check").font(.title).foregroundStyle(model.accentColor)
                Spacer()
                Button(role: .cancel, action: model.cancelCompassCheck) {
                    Text("Cancel")
                }.buttonStyle(.bordered).frame(maxHeight: 30)
                Button(action: model.moveStateForward) {
                    Text(model.moveStateForwardText)
                }.buttonStyle(.borderedProminent)
            }
            Spacer()

            switch model.stateOfCompassCheck {
            case .inform:
                CompassCheckInformView(model: model)
            case .currentPriorities:
                CompassCheckCurrentPriorities(model: model)
            case .pending:
                CompassCheckPendingResponses(model: model)
            case .review:
                CompassCheckNextPriorities(model: model)
            case .dueDate:
                CompassCheckDueDate(model: model)
            case .plan:
                CompassCheckPlanDay(model: model, date: .today)
            }
            Spacer()
        }.padding(4).frame(minHeight: 350, idealHeight: 600)
    }
    //                .overlay {
    //                    GeometryReader { geometry in
    //                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
    //                    }
    //                }
    //                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
    //                    sheetHeight = newHeight
    //                }
    //                .presentationDetents([.height(sheetHeight)])
}

#Preview {
    let model = dummyViewModel()
    model.stateOfCompassCheck = .review
    return CompassCheckDialog(model: model)
}
