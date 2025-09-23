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
    let fontSize: CGFloat
    let iconSize: CGFloat
    let horizontalPadding: CGFloat
    let verticalSpacing: CGFloat
    let itemSpacing: CGFloat
    let showHeader: Bool
    
    static func forFamily(_ family: WidgetFamily) -> WidgetSizeConfig {
        switch family {
        case .systemSmall:
            return WidgetSizeConfig(
                maxPriorities: 3,
                fontSize: 16,
                iconSize: 20,
                horizontalPadding: 0,
                verticalSpacing: 3,
                itemSpacing: 2,
                showHeader: false
            )
        case .systemMedium:
            return WidgetSizeConfig(
                maxPriorities: 5,
                fontSize: 18,
                iconSize: 22,
                horizontalPadding: 2,
                verticalSpacing: 6,
                itemSpacing: 3,
                showHeader: true
            )
        case .systemLarge:
            return WidgetSizeConfig(
                maxPriorities: 6,
                fontSize: 24,
                iconSize: 24,
                horizontalPadding: 2,
                verticalSpacing: 6,
                itemSpacing: 3,
                showHeader: true
            )
        case .systemExtraLarge:
            return WidgetSizeConfig(
                maxPriorities: 7,
                fontSize: 28,
                iconSize: 26,
                horizontalPadding: 2,
                verticalSpacing: 6,
                itemSpacing: 3,
                showHeader: true
            )
        #if os(watchOS)
        case .accessoryRectangular:
            return WidgetSizeConfig(
                maxPriorities: 3,
                fontSize: 11,
                iconSize: 14,
                horizontalPadding: 0,
                verticalSpacing: 2,
                itemSpacing: 1,
                showHeader: false
            )
        case .accessoryCircular:
            return WidgetSizeConfig(
                maxPriorities: 1,
                fontSize: 9,
                iconSize: 12,
                horizontalPadding: 0,
                verticalSpacing: 1,
                itemSpacing: 1,
                showHeader: false
            )
        case .accessoryInline:
            return WidgetSizeConfig(
                maxPriorities: 1,
                fontSize: 9,
                iconSize: 12,
                horizontalPadding: 0,
                verticalSpacing: 1,
                itemSpacing: 1,
                showHeader: false
            )
        #endif
        default:
            return WidgetSizeConfig(
                maxPriorities: 3,
                fontSize: 13,
                iconSize: 16,
                horizontalPadding: 2,
                verticalSpacing: 6,
                itemSpacing: 3,
                showHeader: true
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
        HStack(spacing: config.itemSpacing) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: config.iconSize, height: config.iconSize)
                Image(systemName: imgPriority)
                    .foregroundStyle(Color.priority)
                    .font(.system(size: config.iconSize * 0.5))
            }
            Text(item)
                .font(.system(size: config.fontSize))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
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
                .foregroundStyle(Color.white)
                .font(.system(size: config.fontSize + 3, weight: .medium))
                .frame(width: config.iconSize + 1, height: config.iconSize + 1)
            Text("Today")
                .font(.system(size: config.fontSize + 3, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: config.iconSize + 4, height: config.iconSize + 4)
                Image(systemName: preferences.didCompassCheckToday ? imgCompassCheckDone : imgCompassCheckPending)
                    .foregroundStyle(preferences.didCompassCheckToday ? Color.closed : Color.open)
                    .font(.system(size: config.fontSize + 3, weight: .medium))
                    .frame(width: config.iconSize + 1, height: config.iconSize + 1)
            }
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
