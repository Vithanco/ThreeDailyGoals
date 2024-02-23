//
//  StreakView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/02/2024.
//

import SwiftUI

extension TaskManagerViewModel {
    func streakView() -> Text {
        return Text("\(Image(systemName: imgStreak)) \(streakText)").foregroundStyle(Color.red)  //- Time:
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
