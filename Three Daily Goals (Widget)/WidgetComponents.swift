//
//  WidgetComponents.swift
//  Three Daily Goals (Widget)
//
//  Extracted from WPriorities.swift for better organization
//

import Foundation
import SwiftUI
import WidgetKit
import tdgCoreWidget

// MARK: - Widget Size Configuration
struct WidgetSizeConfig {
    let maxPriorities: Int
    let font: Font
    let fontSize: CGFloat
    let iconSize: CGFloat
    let spacing: CGFloat
    
    static func forFamily(_ family: WidgetFamily) -> WidgetSizeConfig {
        switch family {
        case .systemSmall:
            return WidgetSizeConfig(
                maxPriorities: 3,
                font: .system(size: 13),
                fontSize: 13,
                iconSize: 16,
                spacing: 4
            )
        case .systemMedium:
            return WidgetSizeConfig(
                maxPriorities: 4,
                font: .system(size: 15),
                fontSize: 15,
                iconSize: 18,
                spacing: 6
            )
        case .systemLarge:
            return WidgetSizeConfig(
                maxPriorities: 5,
                font: .system(size: 21),
                fontSize: 21,
                iconSize: 20,
                spacing: 8
            )
        case .systemExtraLarge:
            return WidgetSizeConfig(
                maxPriorities: 6,
                font: .system(size: 25),
                fontSize: 25,
                iconSize: 22,
                spacing: 10
            )
        #if os(watchOS)
        case .accessoryRectangular:
            return WidgetSizeConfig(
                maxPriorities: 3,
                font: .system(size: 11),
                fontSize: 11,
                iconSize: 14,
                spacing: 2
            )
        case .accessoryCircular:
            return WidgetSizeConfig(
                maxPriorities: 1,
                font: .system(size: 9),
                fontSize: 9,
                iconSize: 12,
                spacing: 1
            )
        case .accessoryInline:
            return WidgetSizeConfig(
                maxPriorities: 1,
                font: .system(size: 9),
                fontSize: 9,
                iconSize: 12,
                spacing: 1
            )
        #endif
        default:
            return WidgetSizeConfig(
                maxPriorities: 3,
                font: .system(size: 13),
                fontSize: 13,
                iconSize: 16,
                spacing: 4
            )
        }
    }
}

// MARK: - Priority Item Component
struct WidgetPriorityItem: View {
    let item: String
    let priorityNumber: Int
    let config: WidgetSizeConfig
    
    var body: some View {
        HStack(spacing: config.spacing) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: config.iconSize, height: config.iconSize)
                Image(systemName: imgPriority)
                    .foregroundStyle(Color.priority)
                    .font(.system(size: config.iconSize * 0.5))
            }
            Text(item)
                .font(config.font)
                .lineLimit(2)
        }
    }
}

// MARK: - Streak View Component
struct WidgetStreakView: View {
    let preferences: CloudPreferences
    let config: WidgetSizeConfig
    
    var body: some View {
        HStack(spacing: 3) {
            Text("\(preferences.daysOfCompassCheck)")
                .font(.system(size: config.fontSize + 3, weight: .bold))
                .foregroundStyle(Color.white)
            Image(systemName: preferences.isStreakBroken ? imgStreakBroken : imgStreakActive)
                .foregroundStyle(preferences.daysOfCompassCheck > 0 ? Color.priority : Color.secondary)
                .font(.system(size: config.fontSize + 4, weight: .medium))
                .frame(width: config.iconSize + 1, height: config.iconSize + 1)
            Text("Today")
                .font(.system(size: config.fontSize + 3, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            Image(systemName: preferences.didCompassCheckToday ? imgCompassCheckDone : imgCompassCheckPending)
                .foregroundStyle(preferences.didCompassCheckToday ? Color.closed : Color.open)
                .font(.system(size: config.fontSize + 4, weight: .medium))
                .frame(width: config.iconSize + 1, height: config.iconSize + 1)
        }
    }
}

// MARK: - WatchOS Accessory Widgets
struct WatchAccessoryCircularView: View {
    let preferences: CloudPreferences
    
    var body: some View {
        VStack {
            Text("\(preferences.daysOfCompassCheck)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary)
            Text("days")
                .font(.system(size: 6))
                .foregroundStyle(Color.secondary)
        }
    }
}

struct WatchAccessoryInlineView: View {
    let preferences: CloudPreferences
    let priorities: [String]
    
    var body: some View {
        HStack {
            Text("\(preferences.daysOfCompassCheck) days")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.primary)
            if !priorities.isEmpty {
                Text("• \(priorities.first ?? "")")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct WatchAccessoryRectangularView: View {
    let preferences: CloudPreferences
    let priorities: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(preferences.daysOfCompassCheck) days")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Spacer()
                if preferences.didCompassCheckToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                        .font(.system(size: 8))
                }
            }
            
            if !priorities.isEmpty {
                Text(priorities.prefix(2).joined(separator: ", "))
                    .font(.system(size: 8))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
        }
    }
}
