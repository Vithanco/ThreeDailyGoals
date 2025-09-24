//
//  AppTips.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import SwiftUI
import TipKit

// MARK: - Welcome Tips

struct AddFirstGoalTip: Tip {
    var title: Text {
        Text("Add Your First Goal")
    }
    
    var message: Text? {
        Text("Tap the + button to add your first daily goal. Focus on three important tasks each day.")
    }
    
    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }
}

struct CompassCheckTip: Tip {
    var title: Text {
        Text("Daily Compass Check")
    }
    
    var message: Text? {
        Text("Review your goals daily with the Compass Check. This helps you stay focused and build momentum.")
    }
    
    var image: Image? {
        Image(systemName: "checkmark.circle.fill")
    }
}

struct PriorityTip: Tip {
    var title: Text {
        Text("Set Priorities")
    }
    
    var message: Text? {
        Text("Mark your most important goals as priorities. They'll appear at the top of your list.")
    }
    
    var image: Image? {
        Image(systemName: "star.fill")
    }
}

struct StreakTip: Tip {
    var title: Text {
        Text("Build Your Streak")
    }
    
    var message: Text? {
        Text("Complete your Compass Check daily to build a streak. Consistency is key to success!")
    }
    
    var image: Image? {
        Image(systemName: "flame.fill")
    }
}

// MARK: - Tip Manager

@MainActor
class TipManager: ObservableObject {
    static let shared = TipManager()
    
    private init() {}
    
    func configureTips() {
        // Configure TipKit
        try? Tips.configure([
            AddFirstGoalTip(),
            CompassCheckTip(),
            PriorityTip(),
            StreakTip()
        ])
    }
    
    func resetAllTips() {
        // Reset all tips for testing
        AddFirstGoalTip.invalidate(reason: .tipClosed)
        CompassCheckTip.invalidate(reason: .tipClosed)
        PriorityTip.invalidate(reason: .tipClosed)
        StreakTip.invalidate(reason: .tipClosed)
    }
}


