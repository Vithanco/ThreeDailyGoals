//
//  AppearancePreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import SwiftUI

struct AppearancePreferencesView: View {
    @Environment(CloudPreferences.self) private var preferences

    var body: some View {
        Form {
            Section("Accent Color") {
                ColorPicker(
                    "Accent Color",
                    selection: Binding(
                        get: { preferences.accentColor },
                        set: { preferences.accentColor = $0 }
                    ))
                Button("Reset to Default") {
                    preferences.resetAccentColor()
                }
            }

            Section("Color Theme") {
                ColorThemeSelector()
            }

            Section("Task State Colors") {
                TaskStateColorPreview()
            }

            Section("Visual Style") {
                VisualStyleOptions()
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - Color Theme Selector
struct ColorThemeSelector: View {
    @Environment(CloudPreferences.self) private var preferences

    private let themes = [
        ("Orange", AppColorTheme.orange),
        ("Blue", AppColorTheme.blue),
        ("Green", AppColorTheme.green),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your preferred color theme:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(themes, id: \.0) { name, theme in
                    ColorThemeCard(name: name, theme: theme)
                }
            }
        }
    }
}

struct ColorThemeCard: View {
    let name: String
    let theme: AppColorTheme
    @Environment(CloudPreferences.self) private var preferences

    private var isSelected: Bool {
        preferences.accentColor == theme.primary
    }

    var body: some View {
        VStack(spacing: 8) {
            // Color preview
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
                )

            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? theme.primary : .primary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? theme.primary.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            preferences.accentColor = theme.primary
        }
    }
}

// MARK: - Task State Color Preview
struct TaskStateColorPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task state colors:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                StateColorRow(state: .priority, label: "Priority")
                StateColorRow(state: .open, label: "Open")
                StateColorRow(state: .pendingResponse, label: "Pending Response")
                StateColorRow(state: .closed, label: "Closed")
                StateColorRow(state: .dead, label: "Archived")
            }
        }
    }
}

struct StateColorRow: View {
    let state: TaskItemState
    let label: String

    var body: some View {
        HStack {
            Circle()
                .fill(state.stateColor)
                .frame(width: 16, height: 16)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(state.stateColor.toHex ?? "#000000")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Visual Style Options
struct VisualStyleOptions: View {
    @AppStorage("useEnhancedCards") private var useEnhancedCards = true
    @AppStorage("useStateBadges") private var useStateBadges = true
    @AppStorage("useShadows") private var useShadows = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual enhancements:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Toggle("Enhanced task cards", isOn: $useEnhancedCards)
            Toggle("State badges", isOn: $useStateBadges)
            Toggle("Subtle shadows", isOn: $useShadows)
        }
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    return NavigationView {
        AppearancePreferencesView()
            .environment(appComponents.preferences)
    }
}
