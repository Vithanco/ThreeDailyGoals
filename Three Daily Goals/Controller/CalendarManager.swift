//
//  CalendarManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 22/06/2025.
//

import EventKit
import Foundation

@Observable
class CalendarManager {
    private var eventStore: EKEventStore?

    init() {
        setupCalendarAccess()
    }

    private func setupCalendarAccess() {
        eventStore = EKEventStore()

        // Check current authorization status first
        let authStatus = EKEventStore.authorizationStatus(for: .event)

        switch authStatus {
        case .notDetermined:
            // First time - request permission
            requestCalendarAccess()
        case .authorized, .fullAccess:
            // Already have access - ready to use
            debugPrint("Calendar access already granted")
        // Calendar is ready to use
        case .denied, .restricted:
            // User denied or access restricted
            debugPrint("Calendar access denied or restricted")
            handleAccessDenied()
        case .writeOnly:
            // Has write access but not full access
            debugPrint("Only write access available")
            // You might want to request full access here if needed
            requestCalendarAccess()
        @unknown default:
            debugPrint("Unknown authorization status")
            requestCalendarAccess()
        }
    }

    private func requestCalendarAccess() {
        guard let eventStore = eventStore else { return }

        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugPrint("Calendar access error: \(error)")
                    return
                }

                if granted {
                    debugPrint("Calendar access granted")
                    // Access granted - calendar is ready to use
                    self?.onAccessGranted()
                } else {
                    debugPrint("Calendar access denied by user")
                    self?.handleAccessDenied()
                }
            }
        }
    }

    private func onAccessGranted() {
        // Perform any setup needed when access is granted
        // This is where you'd initialize calendar-dependent features
    }

    private func handleAccessDenied() {
        // Handle the case where access is denied
        // You might want to show an alert directing user to Settings
    }

    // Check if calendar access is available
    var hasCalendarAccess: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .authorized || status == .fullAccess
    }

    // Get the event store (only if access is granted)
    var calendar: EKEventStore? {
        return hasCalendarAccess ? eventStore : nil
    }
}
//
//// Usage example:
//class ViewController: UIViewController {
//    private let calendarManager = CalendarManager()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Calendar access is automatically handled by CalendarManager
//        // Use calendarManager.calendar when you need to access events
//    }
//
//    private func createEvent() {
//        guard let eventStore = calendarManager.calendar else {
//            debugPrint("No calendar access available")
//            return
//        }
//
//        // Use eventStore to create events
//        let event = EKEvent(eventStore: eventStore)
//        // ... configure event
//    }
//}
