//
//  StateView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/12/2023.
//

import SwiftUI

extension TaskSection {
    var asText: Text {
        return Text("\(Image(systemName: image)) \(text)").font(.title)
    }
}

struct StateView: View {
    let state: TaskItemState
    let accentColor: Color

    var body: some View {
        state.section.asText.foregroundStyle(accentColor)
    }
}

// MARK: - Enhanced State View with Color-Coded System
struct EnhancedStateView: View {
    let state: TaskItemState

    // Enhanced icons with better visual distinction
    private var stateIcon: String {
        switch state {
        case .priority: return "star.fill"
        case .open: return "circle"
        case .pendingResponse: return "clock"
        case .closed: return "checkmark.circle.fill"
        case .dead: return "xmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Enhanced icon with background
            Image(systemName: stateIcon)
                .foregroundColor(state.stateColor)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(state.stateColorLight)
                )

            // State text with improved typography
            Text(state.section.text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(state.stateColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(state.stateColorLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(state.stateColorMedium, lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact State Badge
struct StateBadge: View {
    let state: TaskItemState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.stateColor == .priorityColor ? "star.fill" : "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(state.stateColor)

            Text(state.description)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(state.stateColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(state.stateColorLight)
                .overlay(
                    Capsule()
                        .stroke(state.stateColorMedium, lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    Group {
        VStack(spacing: 16) {
            EnhancedStateView(state: .priority)
            EnhancedStateView(state: .open)
            EnhancedStateView(state: .pendingResponse)
            EnhancedStateView(state: .closed)
            EnhancedStateView(state: .dead)
        }

        HStack(spacing: 8) {
            StateBadge(state: .priority)
            StateBadge(state: .open)
            StateBadge(state: .pendingResponse)
            StateBadge(state: .closed)
            StateBadge(state: .dead)
        }
    }
}
