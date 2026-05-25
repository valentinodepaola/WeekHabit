//
//  HabitReminderService.swift
//  WeekHabit
//

import Foundation
import UserNotifications

enum HabitReminderService {
    private static let identifierPrefix = "habit-reminder"
    private static let maxBodyLength = 120

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    /// Solicita permiso de notificaciones al usuario. Solo válido cuando el
    /// estado es `.notDetermined`; en otros casos retorna el resultado del
    /// estado actual sin presentar el diálogo del sistema.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter
                .current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func refreshReminder(for habit: Habit) async {
        await cancelReminder(for: habit)

        guard shouldScheduleReminder(for: habit) else { return }

        let status = await authorizationStatus()
        guard status.allowsReminderScheduling else { return }
        guard let reminderComponents = reminderTimeComponents(from: habit.reminderTime) else { return }

        for weekdayRaw in habit.activeDaysOfWeekRaw {
            guard Weekday(rawValue: weekdayRaw) != nil else { continue }

            var dateComponents = DateComponents()
            dateComponents.calendar = AppCalendar.current
            dateComponents.timeZone = .current
            dateComponents.weekday = weekdayRaw
            dateComponents.hour = reminderComponents.hour
            dateComponents.minute = reminderComponents.minute

            let content = UNMutableNotificationContent()
            content.title = "Es momento de \(habit.title)"
            content.body = reminderBody(for: habit)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifier(for: habit.id, weekdayRaw: weekdayRaw),
                content: content,
                trigger: trigger
            )

            try? await add(request)
        }
    }

    static func cancelReminder(for habit: Habit) async {
        await cancelReminder(forHabitID: habit.id)
    }

    static func cancelReminder(forHabitID habitID: UUID) async {
        await removePendingRequests(with: identifiers(forHabitID: habitID))
    }

    static func refreshAllReminders(for habits: [Habit]) async {
        await cancelAllHabitReminders()

        for habit in habits {
            await refreshReminder(for: habit)
        }
    }

    private static func shouldScheduleReminder(for habit: Habit) -> Bool {
        habit.isReminderEnabled
            && habit.reminderTime != nil
            && !habit.isFinished()
            && !habit.isPaused()
            && !habit.activeDaysOfWeekRaw.isEmpty
    }

    private static func reminderTimeComponents(from date: Date?) -> DateComponents? {
        guard let date else { return nil }
        return AppCalendar.current.dateComponents([.hour, .minute], from: date)
    }

    private static func reminderBody(for habit: Habit) -> String {
        if let motivation = habit.plans
            .filter({ $0.isActive() })
            .compactMap(\.motivation)
            .map(trimmedText)
            .first(where: { !$0.isEmpty }) {
            return truncated(motivation)
        }

        if let note = habit.note.map(trimmedText), !note.isEmpty {
            return truncated(note)
        }

        return "Un paso pequeño también cuenta hoy."
    }

    private static func trimmedText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func truncated(_ text: String) -> String {
        guard text.count > maxBodyLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxBodyLength)
        return String(text[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private static func identifiers(forHabitID habitID: UUID) -> [String] {
        Weekday.allCases.map { identifier(for: habitID, weekdayRaw: $0.rawValue) }
    }

    private static func identifier(for habitID: UUID, weekdayRaw: Int) -> String {
        "\(identifierPrefix):\(habitID.uuidString):\(weekdayRaw)"
    }

    private static func cancelAllHabitReminders() async {
        let requests = await pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix("\(identifierPrefix):") }

        await removePendingRequests(with: identifiers)
    }

    private static func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private static func removePendingRequests(with identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
