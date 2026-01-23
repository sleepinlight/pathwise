//
//  NotificationService.swift
//  pathwise
//
//  Push notification service for daily nudges
//

import Foundation
import UserNotifications
import Combine

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var hasNotificationPermission = false

    private init() {}

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                self.hasNotificationPermission = granted
            }

            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - Schedule Daily Nudge
    func scheduleDailyNudge(
        for window: GoldenWindow,
        notificationTime: Date
    ) {
        // Remove any existing pending notifications
        cancelAllNotifications()

        let content = UNMutableNotificationContent()
        content.title = "Your Golden Window Awaits ✨"
        content.body = generateNotificationBody(for: window)
        content.sound = .default
        content.badge = 1

        // Create trigger from notification time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "dailyNudge",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // MARK: - Schedule Window Reminder
    func scheduleWindowReminder(for window: GoldenWindow, minutesBefore: Int = 15) {
        let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -minutesBefore,
            to: window.startTime
        ) ?? window.startTime

        // Only schedule if the reminder time is in the future
        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time for Your Walk 🚶"
        content.body = "Your Golden Window starts in \(minutesBefore) minutes. It's \(Int(window.weather.temperature))°F outside!"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderTime.timeIntervalSince(Date()),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "windowReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            }
        }
    }

    // MARK: - Cancel Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelDailyNudge() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["dailyNudge"])
    }

    func cancelWindowReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["windowReminder"])
    }

    // MARK: - Helper Methods
    private func generateNotificationBody(for window: GoldenWindow) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let timeString = timeFormatter.string(from: window.startTime)
        let temp = Int(window.weather.temperature)

        // Try to find the next calendar event to provide context
        return "Good morning! Your Golden Window today is at \(timeString). It'll be \(temp)°F—perfect for a \(window.durationInMinutes)-minute break."
    }

    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        await MainActor.run {
            self.hasNotificationPermission = settings.authorizationStatus == .authorized
        }
    }
}
