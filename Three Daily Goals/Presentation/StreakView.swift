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
        return Text("\(Image(systemName: imgStreak)) Streak: \(self.preferences.daysOfReview) - Next: \(stdOnlyTimeFormat.format(next))").foregroundStyle(Color.red)
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
