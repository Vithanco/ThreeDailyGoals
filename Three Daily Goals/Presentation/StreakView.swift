//
//  StreakView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/02/2024.
//

import SwiftUI

extension TaskManagerViewModel {
    func streakView() -> Text {
        let next = self.nextRegularReviewTime
        let today = preferences.lastReview.isToday ? "Done" : stdOnlyTimeFormat.format(next)
        return Text("\(Image(systemName: imgStreak)) Streak: \(self.preferences.daysOfReview), today: \(today)").foregroundStyle(Color.red)  //- Time:
    }
}

struct StreakViewHelper: View {
    var body: some View {
        dummyViewModel().streakView()
    }
}

#Preview {
    StreakViewHelper()
}
