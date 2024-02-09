//
//  StreakView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/02/2024.
//

import SwiftUI

func streakView(model: TaskManagerViewModel) -> Text {
    return Text("\(Image(systemName: imgStreak)) Streak \(model.preferences.daysOfReview) \nReview sc: \(stdDateTimeFormat.format(model.preferences.nextReviewTime))").foregroundStyle(Color.red)
        
}

struct StreakViewHelper: View {
    var body: some View {
        streakView(model: dummyViewModel())
    }
}

#Preview {
    StreakViewHelper()
}
