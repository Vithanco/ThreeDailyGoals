//
//  PushNotification.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import Foundation
import tdgCoreMain
@preconcurrency import UserNotifications

let id = "3dg.dailyCompssCheck"
let streakReminderId = "3dg.streakReminder"

@MainActor
public class PushNotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    let compassCheckManager: CompassCheckManager

    init(compassCheckManager: CompassCheckManager) {
        self.compassCheckManager = compassCheckManager
    }

    public func userNotificationCenter(
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
public final class PushNotificationManager {
    // Use a computed accessor instead of a stored property
    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }
    private var delegate: PushNotificationDelegate?

    init() {}

    func checkNotificationAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func scheduleStreakReminderNotification(preferences: CloudPreferences, timeProvider: TimeProvider) async {
        guard preferences.daysOfCompassCheck > 3 && !preferences.didCompassCheckToday else {
            center.removePendingNotificationRequests(withIdentifiers: [streakReminderId])
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: [streakReminderId])

        var components = DateComponents()
        components.hour = 11
        components.minute = 0
        components.calendar = timeProvider.calendar

        let elevenAM = timeProvider.calendar.date(from: components) ?? timeProvider.now
        guard elevenAM > timeProvider.now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Alive! 🔥"
        content.body = "You have a \(preferences.daysOfCompassCheck)-day streak - don't break it now! Time for your Compass Check."

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: streakReminderId, content: content, trigger: trigger)

        do {
            try await center.add(request)   // stays on MainActor, no extra Task, no captured stored property
        } catch {
            print("Not able to add streak reminder notification: \(error.localizedDescription)")
        }
    }

    func scheduleSystemPushNotification(timing: DateComponents, model: CompassCheckManager) async {
        if delegate == nil {
            delegate = PushNotificationDelegate(compassCheckManager: model)
            center.delegate = delegate
        }

        center.removePendingNotificationRequests(withIdentifiers: [id])

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge])
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Time for the daily Compass Check!"
            content.body = "Click here for starting the Compass Check"

            let trigger = UNCalendarNotificationTrigger(dateMatching: timing, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            try await center.add(request)
        } catch {
            print("Authorization/scheduling failed: \(error.localizedDescription)")
        }
    }
    
    /// Cancel all compass check related notifications
    func cancelCompassCheckNotifications() async {
        center.removePendingNotificationRequests(withIdentifiers: [id, streakReminderId])
    }
}
