//
//  DebugPreferencesView.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import SwiftUI
import tdgCoreMain

struct DebugPreferencesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug Options")
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Tips & Onboarding")
                    .font(.headline)

                Button("Reset All Tips") {
                    TipManager.shared.resetAllTips()
                }
                .buttonStyle(.bordered)
                .help("Reset all tips to show them again")

                Text("This will make all tips appear again for testing purposes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    DebugPreferencesView()
}
