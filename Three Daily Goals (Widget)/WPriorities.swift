//
//  WPriorities.swift
//  Three Daily Goals (Widget)Extension
//
//  Created by Klaus Kneupner on 21/12/2023.
//  Refactored for better maintainability
//

import Foundation
import SwiftUI
import WidgetKit
import tdgCoreWidget

struct WPriorities: View {
    let preferences: CloudPreferences
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily
    
    private var config: WidgetSizeConfig {
        WidgetSizeConfig.forFamily(widgetFamily)
    }
    
    private var availablePriorities: [String] {
        var priorities: [String] = []
        for i in 1...5 {
            let priority = preferences.getPriority(nr: i)
            if !priority.isEmpty {
                priorities.append(priority)
            }
        }
        return priorities
    }
    
    private var displayText: String {
        let priorities = availablePriorities
        
        if priorities.isEmpty {
            return "Run a compass check to set your goals"
        }
        
        if priorities.count <= config.maxPriorities {
            return priorities.joined(separator: ", ")
        } else {
            let first = priorities[0]
            let remaining = priorities.count - 1
            return "\(first) + \(remaining) more"
        }
    }
    
    private var shouldShowIndividualItems: Bool {
        let priorities = availablePriorities
        return !priorities.isEmpty && priorities.count <= config.maxPriorities
    }

    var body: some View {
        #if os(watchOS)
        watchOSLayout
        #else
        standardLayout
        #endif
    }
    
    // MARK: - WatchOS Layout
    @ViewBuilder
    private var watchOSLayout: some View {
        switch widgetFamily {
        case .accessoryCircular:
            WatchAccessoryCircularView(preferences: preferences)
        case .accessoryInline:
            WatchAccessoryInlineView(preferences: preferences, priorities: availablePriorities)
        case .accessoryRectangular:
            WatchAccessoryRectangularView(preferences: preferences, priorities: availablePriorities)
        default:
            standardLayout
        }
    }
    
    // MARK: - Standard Layout
    @ViewBuilder
    private var standardLayout: some View {
        VStack(alignment: .leading, spacing: widgetFamily == .systemSmall ? 3 : 6) {
            WidgetStreakView(preferences: preferences, config: config)
            
            VStack(alignment: .leading, spacing: widgetFamily == .systemSmall ? 2 : 3) {
                if widgetFamily != .systemSmall {
                    headerView
                }
                
                if shouldShowIndividualItems {
                    individualItemsView
                } else {
                    summaryView
                }
            }
        }
        .padding(.horizontal, widgetFamily == .systemSmall ? 0 : 4)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: widgetFamily == .systemSmall ? 4 : 6) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: widgetFamily == .systemSmall ? 16 : 18, height: widgetFamily == .systemSmall ? 16 : 18)
                .opacity(0.8)
            
            Text("Goals")
                .font(widgetFamily == .systemSmall ? .system(size: 15, weight: .semibold) : .headline)
                .foregroundStyle(Color.primary)
        }
    }
    
    @ViewBuilder
    private var individualItemsView: some View {
        ForEach(Array(availablePriorities.enumerated()), id: \.offset) { index, priority in
            WidgetPriorityItem(item: priority, priorityNumber: index + 1, config: config)
        }
    }
    
    @ViewBuilder
    private var summaryView: some View {
        Text(displayText)
            .font(.system(size: widgetFamily == .systemSmall ? 11 : 13))
            .foregroundStyle(Color.secondary)
            .lineLimit(widgetFamily == .systemSmall ? 2 : 3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    WPriorities(preferences: CloudPreferences(testData: true, timeProvider: RealTimeProvider()))
}
