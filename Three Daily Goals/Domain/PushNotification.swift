//
//  PushNotification.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import Foundation
import UserNotifications

let id = "3dg.dailyCompssCheck"

extension PushNotificationDelegate: @unchecked Sendable {}

private var delegate: PushNotificationDelegate? = nil

class PushNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let model: TaskManagerViewModel

    init(model: TaskManagerViewModel) {
        self.model = model
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
                await model.startCompassCheckNow()
            }
        default:
            break
        }

        completionHandler()
    }
}

func scheduleSystemPushNotification(timing: DateComponents, model: TaskManagerViewModel) {
    let notificationCenter = UNUserNotificationCenter.current()
    if delegate == nil {
        delegate = PushNotificationDelegate(model: model)
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
