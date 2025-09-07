//
//  PushNotification.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import Foundation
import UserNotifications

let id = "3dg.dailyCompssCheck"
let streakReminderId = "3dg.streakReminder"

@MainActor
class PushNotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    let compassCheckManager: CompassCheckManager

    init(compassCheckManager: CompassCheckManager) {
        self.compassCheckManager = compassCheckManager
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {

        // Determine the user action
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            Task {
                 compassCheckManager.startCompassCheckNow()
            }
        default:
            break
        }

        completionHandler()
    }
}

@MainActor
final class PushNotificationManager {
    private var delegate: PushNotificationDelegate?
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func checkNotificationAuthorization() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
    
    func scheduleStreakReminderNotification(preferences: CloudPreferences, timeProvider: TimeProvider) {
        // Only schedule if streak > 3 and CompassCheck is missing
        guard preferences.daysOfCompassCheck > 3 && !preferences.didCompassCheckToday else { 
            // If conditions not met, remove any existing streak reminder
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [streakReminderId])
            return 
        }
        
        // Remove any existing streak reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [streakReminderId])
        
        // Create 11am trigger for today
        var components = DateComponents()
        components.hour = 11
        components.minute = 0
        components.calendar = timeProvider.calendar
        
        // Only schedule if 11am hasn't passed today
        let elevenAM = timeProvider.calendar.date(from: components) ?? timeProvider.now
        guard elevenAM > timeProvider.now else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Alive! 🔥"
        content.body = "You have a \(preferences.daysOfCompassCheck)-day streak - don't break it now! Time for your Compass Check."
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: streakReminderId, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Not able to add streak reminder notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleSystemPushNotification(timing: DateComponents, model: CompassCheckManager) {
        // Ensure delegate is set up on the main actor
        if delegate == nil {
            delegate = PushNotificationDelegate(compassCheckManager: model)
            notificationCenter.delegate = delegate
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])

        notificationCenter.requestAuthorization(options: [.alert, .badge]) { granted, error in
            if error != nil {
                // Handle errors
                return
            }

            guard granted else { return }

            // Configure the content of the notification
            let content = UNMutableNotificationContent()
            content.title = "Time for the daily Compass Check!"
            content.body = "Click here for starting the Compass Check"

            // Configure the trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: timing, repeats: true)

            // Create the notification request
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            // Schedule the notification
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Not able to add notification: \(error.localizedDescription)")
                }
            }
        }
    }
}

