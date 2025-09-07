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

    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    //    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        VStack {

            HStack {
                Text("Daily Compass Check").font(.title).foregroundStyle(Color.priority)
                Spacer()
                if compassCheckManager.state == .inform {
                    Button(action: compassCheckManager.waitABit) {
                        Text("Remind me in 5 min")
                    }.buttonStyle(.bordered).frame(maxHeight: 30)
                } else {
                    Button(action: compassCheckManager.pauseCompassCheck) {
                        Text("Pause for 5 min")
                    }.buttonStyle(.bordered).frame(maxHeight: 30)
                }
                Button(role: .cancel, action: compassCheckManager.cancelCompassCheck) {
                    Text("Cancel")
                }.buttonStyle(.bordered).frame(maxHeight: 30)
                Button(action: compassCheckManager.moveStateForward) {
                    Text(compassCheckManager.moveStateForwardText)
                }.buttonStyle(.borderedProminent)
            }
            Spacer()

            switch compassCheckManager.state.rawValue {
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
                CompassCheckPlanDay(date: timeProviderWrapper.timeProvider.getCompassCheckInterval().end)
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
    let appComponents = setupApp(isTesting: true)
    return CompassCheckDialog()
        .environment(appComponents.preferences)
        .environment(appComponents.compassCheckManager)
}
