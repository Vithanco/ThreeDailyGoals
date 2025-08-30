//
//  WPriorities.swift
//  Three Daily Goals (Widget)Extension
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation
import SwiftUI
import WidgetKit

struct AWPriority: View {
    var item: String
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily

    var font: Font {
        switch widgetFamily {
        case .systemSmall: return .system(size: 12)
        case .systemMedium: return .system(size: 14)
        case .systemLarge: return .system(size: 20)
        case .systemExtraLarge: return .system(size: 24)
        default:
            return .system(size: 12)
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "smallcircle.filled.circle")
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
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.priority)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            Text("\(preferences.daysOfCompassCheck)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
            Text("Today")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.black) //preferences.didCompassCheckToday ? Color.closed : Color.open)
            Image(systemName: preferences.didCompassCheckToday ? "checkmark.circle.fill" : "clock.circle")
                .foregroundStyle(preferences.didCompassCheckToday ? Color.closed : Color.open)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
           
        }
    }
}

struct WPriorities: View {
    let preferences: CloudPreferences
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily

    var headingText: String {
        return "Goals"
    }

    var nrPriorities: Int {
        switch widgetFamily {
        case .systemSmall: return 3
        case .systemMedium: return 3
        case .systemLarge: return 4
        case .systemExtraLarge: return 5
        default:
            return 3
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Use widget-specific streak view
            WStreakView(preferences: preferences)
            
            // Priorities section
            VStack(alignment: .leading, spacing: 4) {
                Text(headingText)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                AWPriority(item: preferences.getPriority(nr: 1))
                AWPriority(item: preferences.getPriority(nr: 2))
                AWPriority(item: preferences.getPriority(nr: 3))
                if nrPriorities > 3 {
                    AWPriority(item: preferences.getPriority(nr: 4))
                }
                if nrPriorities > 4 {
                    AWPriority(item: preferences.getPriority(nr: 5))
                }
            }
        }
    }
}

#Preview {
    WPriorities(preferences: CloudPreferences(testData: true))
}
