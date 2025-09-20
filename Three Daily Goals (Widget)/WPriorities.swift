//
//  WPriorities.swift
//  Three Daily Goals (Widget)Extension
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation
import SwiftUI
import WidgetKit
import tdgCoreWidget

struct AWPriority: View {
    var item: String
    var priorityNumber: Int
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily

    var font: Font {
        switch widgetFamily {
        case .systemSmall: return .system(size: 12)
        case .systemMedium: return .system(size: 14)
        case .systemLarge: return .system(size: 20)
        case .systemExtraLarge: return .system(size: 24)
        #if os(watchOS)
        case .accessoryRectangular: return .system(size: 10)
        case .accessoryCircular: return .system(size: 8)
        case .accessoryInline: return .system(size: 8)
        #endif
        default:
            return .system(size: 12)
        }
    }
    
    var priorityIcon: String {
        switch priorityNumber {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        case 4: return "4.circle.fill"
        case 5: return "5.circle.fill"
        default: return "x.circle.fill"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: priorityIcon)
                .foregroundStyle(Color.priority)
            HStack {
                Text(item).font(self.font)
            }
        }
    }
}

// Widget-specific streak view that doesn't rely on external dependencies
struct WStreakView: View {
    let preferences: CloudPreferences
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(preferences.daysOfCompassCheck)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black)
            Image(systemName: preferences.isStreakBroken ? imgStreakBroken : imgStreak)
                .foregroundStyle(preferences.daysOfCompassCheck > 0 ? Color.priority : Color.secondary)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
            Text("Today")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black)
                .lineLimit(1)
            Image(systemName: preferences.didCompassCheckToday ? imgClosed: imgOpen)
                .foregroundStyle(preferences.didCompassCheckToday ? Color.closed : Color.open)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
        }
    }
}

struct WPriorities: View {
    let preferences: CloudPreferences
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily

    var headingText: String {
        return "Goals"
    }

    var maxPriorities: Int {
        switch widgetFamily {
        case .systemSmall: return 2
        case .systemMedium: return 3
        case .systemLarge: return 4
        case .systemExtraLarge: return 5
        #if os(watchOS)
        case .accessoryRectangular: return 2
        case .accessoryCircular: return 1
        case .accessoryInline: return 1
        #endif
        default:
            return 3
        }
    }
    
    var availablePriorities: [String] {
        var priorities: [String] = []
        for i in 1...5 {
            let priority = preferences.getPriority(nr: i)
            if !priority.isEmpty {
                priorities.append(priority)
            }
        }
        
        // Debug: Print what priorities we found
        print("Widget: Found \(priorities.count) priorities: \(priorities)")
        
        return priorities
    }
    
    var displayText: String {
        let priorities = availablePriorities
        
        if priorities.isEmpty {
            return "Run a compass check to set your goals"
        }
        
        if priorities.count <= maxPriorities {
            // Show all priorities if they fit
            return priorities.joined(separator: ", ")
        } else {
            // Show first priority + summary
            let first = priorities[0]
            let remaining = priorities.count - 1
            return "\(first) + \(remaining) more"
        }
    }
    
    var shouldShowIndividualItems: Bool {
        let priorities = availablePriorities
        return !priorities.isEmpty && priorities.count <= maxPriorities
    }

    var body: some View {
        #if os(watchOS)
        // Use different layouts for watchOS accessory widgets
        if widgetFamily == .accessoryCircular {
            // Circular watch face complication - show streak count
            VStack {
                Text("\(preferences.daysOfCompassCheck)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text("days")
                    .font(.system(size: 6))
                    .foregroundStyle(Color.secondary)
            }
        } else if widgetFamily == .accessoryInline {
            // Inline watch face complication - show compact info
            HStack {
                Text("\(preferences.daysOfCompassCheck) days")
                    .font(.system(size: 8, weight: .medium))
                if !availablePriorities.isEmpty {
                    Text("• \(availablePriorities.first ?? "")")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }
        } else if widgetFamily == .accessoryRectangular {
            // Rectangular watch widget - compact layout
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(preferences.daysOfCompassCheck) days")
                        .font(.system(size: 10, weight: .semibold))
                    Spacer()
                    if preferences.didCompassCheckToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                            .font(.system(size: 8))
                    }
                }
                
                if !availablePriorities.isEmpty {
                    Text(availablePriorities.prefix(2).joined(separator: ", "))
                        .font(.system(size: 8))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
            }
        } else {
            // Standard layout for system widgets (watchOS)
            VStack(alignment: .leading, spacing: 6) {
                // Use widget-specific streak view
                WStreakView(preferences: preferences)
                
                // Priorities section with custom app logo
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .opacity(0.8)
                        
                        Text(headingText)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                    }
                    
                    if shouldShowIndividualItems {
                        // Show individual priority items
                        ForEach(Array(availablePriorities.enumerated()), id: \.offset) { index, priority in
                            AWPriority(item: priority, priorityNumber: index + 1)
                        }
                    } else {
                        // Show summary text with more space
                        Text(displayText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        #else
        // Standard layout for system widgets (iOS/macOS)
        VStack(alignment: .leading, spacing: 6) {
            // Use widget-specific streak view
            WStreakView(preferences: preferences)
            
            // Priorities section with custom app logo
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .opacity(0.8)
                    
                    Text(headingText)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                }
                
                if shouldShowIndividualItems {
                    // Show individual priority items
                    ForEach(Array(availablePriorities.enumerated()), id: \.offset) { index, priority in
                        AWPriority(item: priority, priorityNumber: index + 1)
                    }
                } else {
                    // Show summary text with more space
                    Text(displayText)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 4)
        #endif
    }
}

#Preview {
    WPriorities(preferences: CloudPreferences(testData: true, timeProvider: RealTimeProvider()))
}
