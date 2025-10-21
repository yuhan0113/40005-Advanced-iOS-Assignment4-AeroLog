//
//  NotificationManager.swift
//  AeroLog
//
//  Created by Yu-Han on 15/10/2025
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        // Ensure we receive notifications while app is in foreground
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
        // Register categories regardless
        registerNotificationCategories()
    }

    func scheduleFlightReminder(for task: FlightTask) {
        guard let departureDate = Self.buildDate(from: task.dueDate, timeString: task.departureTime) else { return }

        // Schedule 30 minutes before departure if in the future; otherwise at departure time if still future
        let thirtyMinutesBefore = departureDate.addingTimeInterval(-30 * 60)
        let triggerDate = max(thirtyMinutesBefore, Date())

        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Flight Reminder"
        content.subtitle = "\(task.airline.rawValue) \(task.flightNumber)"
        content.body = "\(task.departure) → \(task.arrival) departs at \(task.departureTime)"
        content.sound = .default
        content.categoryIdentifier = "flight.reminder"
        content.userInfo = [
            "flightCode": task.flightNumber,
            "departure": task.departure,
            "arrival": task.arrival,
            "departureTime": task.departureTime
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId(for: task), content: content, trigger: trigger)
        center.add(request)

        // Schedule 2 hours before, if in future
        let twoHoursBefore = departureDate.addingTimeInterval(-2 * 60 * 60)
        if twoHoursBefore > Date() {
            let twoHourContent = UNMutableNotificationContent()
            twoHourContent.title = "Flight Reminder (2h)"
            twoHourContent.subtitle = content.subtitle
            twoHourContent.body = content.body
            twoHourContent.sound = content.sound
            twoHourContent.categoryIdentifier = content.categoryIdentifier
            twoHourContent.userInfo = content.userInfo
            let twoHourTrigger = UNTimeIntervalNotificationTrigger(timeInterval: twoHoursBefore.timeIntervalSinceNow, repeats: false)
            let twoHourRequest = UNNotificationRequest(identifier: notificationId(for: task) + "-2h", content: twoHourContent, trigger: twoHourTrigger)
            center.add(twoHourRequest)
        }

        // Immediate confirmation notification (2 seconds) so user can test flow
        let immediateContent = UNMutableNotificationContent()
        immediateContent.title = "Flight Added"
        immediateContent.subtitle = content.subtitle
        immediateContent.body = content.body
        immediateContent.sound = content.sound
        immediateContent.categoryIdentifier = content.categoryIdentifier
        immediateContent.userInfo = content.userInfo
        let immediateTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let immediateRequest = UNNotificationRequest(identifier: notificationId(for: task) + "-added", content: immediateContent, trigger: immediateTrigger)
        center.add(immediateRequest)
    }

    func removeReminder(for task: FlightTask) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId(for: task)])
        center.removeDeliveredNotifications(withIdentifiers: [notificationId(for: task)])
    }

    private func notificationId(for task: FlightTask) -> String {
        return "flight-reminder-\(task.id.uuidString)"
    }

    private static func buildDate(from baseDate: Date, timeString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        guard let timeOnly = dateFormatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: timeOnly)
        return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: baseDate)
    }

    private func registerNotificationCategories() {
        let addAction = UNNotificationAction(
            identifier: "add.flight",
            title: "Add to My Flights",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "dismiss.flight",
            title: "Dismiss",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "flight.reminder",
            actions: [addAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - UNUserNotificationCenterDelegate
    // Present banner/sound while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
