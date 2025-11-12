//
//  CompassCheckStepsPreferencesView.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import SwiftUI
import tdgCoreMain

public struct CompassCheckStepsPreferencesView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: imgCompassCheck)
                            .foregroundColor(Color.priority)
                            .font(.title2)
                        Text("Compass Check Steps")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.priority)
                    }

                    Text("Configure which steps are included in your daily Compass Check process.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                // Individual step configuration sections
                ForEach(Array(compassCheckManager.steps.enumerated()), id: \.element.id) { index, step in
                    VStack(alignment: .leading, spacing: 6) {
                        // Step header with toggle
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        preferences.isCompassCheckStepEnabled(stepId: step.id) ? .primary : .secondary
                                    )
                                    .animation(
                                        .easeInOut(duration: 0.2),
                                        value: preferences.isCompassCheckStepEnabled(stepId: step.id))

                                Text(step.description)
                                    .font(.caption)
                                    .foregroundColor(
                                        preferences.isCompassCheckStepEnabled(stepId: step.id)
                                            ? .secondary : Color.secondary.opacity(0.6)
                                    )
                                    .lineLimit(2)
                                    .animation(
                                        .easeInOut(duration: 0.2),
                                        value: preferences.isCompassCheckStepEnabled(stepId: step.id))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Toggle(
                                    "",
                                    isOn: Binding(
                                        get: { preferences.isCompassCheckStepEnabled(stepId: step.id) },
                                        set: { preferences.setCompassCheckStepEnabled(stepId: step.id, enabled: $0) }
                                    )
                                )
                                .toggleStyle(.switch)
                                .scaleEffect(0.65)

                                if step.id == "plan" {
                                    Text("Coming Soon")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .cornerRadius(3)
                                }
                            }
                        }

                        // Step-specific configuration (if available)
                        if let configView = step.configurationView() {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Rectangle()
                                        .fill(Color.primary.opacity(0.2))
                                        .frame(width: 2, height: 16)
                                    Text("Configuration")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                }
                                .padding(.vertical, 2)

                                configView
                            }
                            .padding(.leading, 12)
                            .padding(.trailing, 4)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(Color.background).opacity(0.5))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    CompassCheckStepsPreferencesView()
        .environment(appComponents.preferences)
        .environment(appComponents.compassCheckManager)
}
