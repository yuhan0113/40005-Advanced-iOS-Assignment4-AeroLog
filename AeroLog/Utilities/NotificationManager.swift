//
//  NotificationManager.swift
//  AeroLog
//
//  Created by Yu-Han on 15/10/2025
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
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

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId(for: task), content: content, trigger: trigger)
        center.add(request)
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
}
