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
    
    private var displayedPriorities: [String] {
        return Array(availablePriorities.prefix(config.maxPriorities))
    }
    
    private var remainingTasksCount: Int {
        return max(0, availablePriorities.count - config.maxPriorities)
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
        VStack(alignment: .leading, spacing: config.verticalSpacing) {
            WidgetStreakView(preferences: preferences, config: config)
            
            VStack(alignment: .leading, spacing: config.itemSpacing) {
                if config.showHeader {
                    headerView
                }
                
                individualItemsView
                
                if remainingTasksCount > 0 {
                    remainingTasksView
                }
            }
        }
        .padding(.horizontal, config.horizontalPadding)
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: config.itemSpacing) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: config.iconSize + 4, height: config.iconSize + 4)
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: config.iconSize, height: config.iconSize)
            }
            
            Text("Goals")
                .font(.system(size: config.fontSize + 2, weight: .semibold))
                .foregroundStyle(Color.white)
        }
    }
    
    @ViewBuilder
    private var individualItemsView: some View {
        ForEach(Array(displayedPriorities.enumerated()), id: \.offset) { index, priority in
            WidgetPriorityItem(item: priority, priorityNumber: index + 1, config: config)
        }
    }
    
    @ViewBuilder
    private var remainingTasksView: some View {
        Text("+ \(remainingTasksCount) tasks")
            .font(.system(size: config.fontSize - 2))
            .foregroundStyle(Color.secondary)
            .lineLimit(1)
    }
}

#Preview {
    WPriorities(preferences: CloudPreferences(testData: true, timeProvider: RealTimeProvider()))
}
