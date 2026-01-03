//
//  MoveToGraveyardStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI
import tdgCoreMain

@MainActor
public struct MoveToGraveyardStep: @MainActor CompassCheckStep {
    public let id: String = "moveToGraveyard"
    public let name: String = "Move unused Tasks to Graveyard"
    public let description: String =
        "Automatically moves old tasks to the graveyard after they haven't been used for a specified number of days."

    /// This is a silent step - it executes automatically without user interaction
    public var isSilent: Bool {
        return true
    }

    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        // Silent steps don't need a view, but we provide a minimal one for protocol compliance
        AnyView(
            Text("Moving unused tasks to graveyard...")
                .foregroundStyle(.secondary)
        )
    }

    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // This is where the actual work happens - move old tasks to graveyard
        let killedCount = dataManager.killOldTasks(expireAfter: preferences.expiryAfter, preferences: preferences)
        debugPrint("MoveToGraveyardStep: Moved \(killedCount) old tasks to graveyard")
    }

    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // This step is always applicable - it can always check for old tasks
        return true
    }

    @ViewBuilder
    public func configurationView() -> AnyView? {
        AnyView(MoveToGraveyardConfigurationView())
    }
}

/// Configuration view for MoveToGraveyardStep
public struct MoveToGraveyardConfigurationView: View {
    @Environment(CloudPreferences.self) private var preferences

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expire after")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Stepper(
                    value: Binding(
                        get: { preferences.expiryAfter },
                        set: { preferences.expiryAfter = $0 }
                    ),
                    in: 30...1040,
                    step: 10,
                    label: {
                        Text("\(preferences.expiryAfter)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.priority)
                            .frame(minWidth: 50, alignment: .leading)
                    }
                )

                Text("days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Text("Tasks will be moved to the graveyard after this many days of inactivity.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
        }
        .padding(.vertical, 4)
    }
}
