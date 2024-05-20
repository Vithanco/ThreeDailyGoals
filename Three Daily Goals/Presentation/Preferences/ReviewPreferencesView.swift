//
//  ReviewPreferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI

struct ReviewPreferencesView : View {
    @Bindable var model: TaskManagerViewModel
    
    var lastReview: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: model.preferences.lastReview)
    }
    
    var body: some View {
        VStack{
            Spacer()
            Text("Daily Reviews are at the heart of Three Daily Goals. Choose when you want to plan your Daily Review. In the morning? Or the evening before?").multilineTextAlignment(.center).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            Text("Three Daily Goals is assuming that you should do a review to occur at least once between noon of one day and noon the next day.").multilineTextAlignment(.center)
            Spacer().frame(height: 10)
            GroupBox{
                HStack{
                    Text("Last Review was:")
                    Text(lastReview).foregroundColor(model.accentColor)
                }.padding(5)
                
                model.streakView().padding(EdgeInsets(top: 5, leading: 5, bottom: 10, trailing: 5))

                
                Text("Current Review Interval").bold()
                HStack{
                    Text ("From:")
                    Text (model.preferences.currentReviewInterval.start.timeAgoDisplay())
                    
                    Text ("To:")
                    Text (model.preferences.currentReviewInterval.end.timeAgoDisplay())
                }
                HStack{
                    Text ("Done for this period: ")
                    Text (model.didLastReviewHappenInCurrentReviewInterval() ? "yes" : "no")
                }
            }
            GroupBox {
                DatePicker("Time of Review Notification", selection: $model.preferences.reviewTime, displayedComponents: .hourAndMinute).frame(maxWidth: 258).padding(5)
                Button("Set Review Time") {
                    model.setupReviewNotification()
                }.buttonStyle(.bordered).padding(5)
                
                //                Spacer()
                //            }
                Text("or")
                
                Button( "No Notifications Please", role: .destructive){
                    model.deleteNotifications()
                }.buttonStyle(.bordered).padding(5)
            }.frame(minWidth: 200)
            Spacer()
            Spacer()
        }.padding(10).frame(maxWidth: 400, minHeight: 500)
    }
    
}

#Preview {
    ReviewPreferencesView(model: dummyViewModel())
}
