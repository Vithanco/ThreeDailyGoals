//
//  PushNotification.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import Foundation
import UserNotifications

let id = "3dg.dailyCompssCheck"

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

