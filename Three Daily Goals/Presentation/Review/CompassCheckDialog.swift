//
//  ReviewDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import tdgCoreMain

public struct InnerHeightPreferenceKey: PreferenceKey {
    public static let defaultValue: CGFloat = .zero
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct CompassCheckDialog: View {

    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    //    @State private var sheetHeight: CGFloat = .zero

    public var body: some View {
        VStack(spacing: 0) {
            // Fixed header with navigation buttons
            HStack {
                Text("Daily Compass Check").font(.title).foregroundStyle(Color.priority)
                Spacer()
                Button(action: compassCheckManager.goBackOneStep) {
                    Text("Back")
                }
                .buttonStyle(.bordered)
                .frame(maxHeight: 30)
                .disabled(!compassCheckManager.canGoBack)
                Button(role: .cancel, action: compassCheckManager.cancelCompassCheck) {
                    Text("Cancel")
                }.buttonStyle(.bordered).frame(maxHeight: 30)
                Button(action: compassCheckManager.moveStateForward) {
                    Text(compassCheckManager.moveStateForwardText)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.priority)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }.buttonStyle(.plain)
            }
            .padding(4)

            // Step progress bar (one segment per visible step, lit up to current).
            let totalSteps = compassCheckManager.visibleSteps.count
            if totalSteps > 1 {
                let currentIndex = compassCheckManager.currentVisibleIndex
                HStack(spacing: 4) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentIndex ? Color.priority : Color.neutral200)
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }

            Divider()

            // Scrollable step content
            ScrollView {
                compassCheckManager.getCurrentStepView()
                    .padding(.vertical)
            }
        }
        .frame(minHeight: 350, idealHeight: 600)
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
    CompassCheckDialog()
        .environment(appComponents.preferences)
        .environment(appComponents.compassCheckManager)
}
