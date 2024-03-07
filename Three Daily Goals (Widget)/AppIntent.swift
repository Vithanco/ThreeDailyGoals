//
//  AppIntent.swift
//  Three Daily Goals (Widget)
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Three Daily Goals"
    static let description = IntentDescription("Display today's priorities, as configured in the iOS/macOS Apps.")

//    // An example configurable parameter.
//    @Parameter(title: "Favorite Emoji", default: "😃")
//    var favoriteEmoji: String
}
