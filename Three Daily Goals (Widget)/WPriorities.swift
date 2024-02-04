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
            case .systemSmall : return .system(size: 10)
            case .systemMedium: return .system(size: 12)
            case .systemLarge: return .system(size: 16)
            case .systemExtraLarge: return .system(size: 20)
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

struct WPriorities: View {
    let preferences: CloudPreferences
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily
    
    
    var headingText: String {
        switch widgetFamily {
            case .systemSmall : return "Today"
            case .systemMedium: return "Today's Priorities"
            case .systemLarge: return "Today's Priorities"
            case .systemExtraLarge: return "Today's Priorities"
            default:
                return "Today's Priorities"
        }
    }
    
    var nrPriorities : Int {
        switch widgetFamily {
            case .systemSmall : return 3
            case .systemMedium: return 3
            case .systemLarge: return 4
            case .systemExtraLarge: return 5
            default:
                return 3
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(Image(systemName: "flame.fill")) Streak: \(preferences.daysOfReview)").font(.title2).foregroundStyle(Color.red)
            Section (header: Text("\(Image(systemName: imgToday)) Today").font(.title).foregroundStyle(preferences.accentColor)){
                    AWPriority( item: preferences.getPriority(nr: 1))
                AWPriority( item: preferences.getPriority(nr: 2))
                AWPriority( item: preferences.getPriority(nr: 3))
                if nrPriorities > 3 {
                    AWPriority( item: preferences.getPriority(nr: 4))
                }
                if nrPriorities > 4 {
                    AWPriority( item: preferences.getPriority(nr: 5))
                }
            }
        }
    }
}

#Preview {
    WPriorities(preferences: dummyPreferences())
}
