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

    @Environment(TaskManagerViewModel.self) private var model
    @Environment(CloudPreferences.self) private var preferences
    //    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        VStack {

            HStack {
                Text("Daily Compass Check").font(.title).foregroundStyle(preferences.accentColor)
                Spacer()
                Button(role: .cancel, action: model.compassCheckManager.cancelCompassCheck) {
                    Text("Cancel")
                }.buttonStyle(.bordered).frame(maxHeight: 30)
                Button(action: model.compassCheckManager.moveStateForward) {
                    Text(model.compassCheckManager.moveStateForwardText)
                }.buttonStyle(.borderedProminent)
            }
            Spacer()

            switch model.compassCheckManager.state.rawValue {
            case "inform":
                CompassCheckInformView()
            case "currentPriorities":
                CompassCheckCurrentPriorities()
            case "pending":
                CompassCheckPendingResponses()
            case "review":
                CompassCheckNextPriorities()
            case "dueDate":
                CompassCheckDueDate()
            case "plan":
                CompassCheckPlanDay(date: getCompassCheckInterval().end)
            default:
                CompassCheckInformView()
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
    CompassCheckDialog()
        .environment(dummyViewModel())
}
