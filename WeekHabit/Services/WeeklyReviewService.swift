//
//  WeeklyReviewService.swift
//  WeekHabit
//

import Foundation
import UserNotifications

enum WeeklyReviewService {
    static let notificationIdentifier = "weekly-review:reminder"

    static func currentWeekStart(reference: Date = .now, preferredWeekday: Weekday) -> Date {
        let reviewDay = latestReviewDay(reference: reference, preferredWeekday: preferredWeekday)
        return AppCalendar.weekRange(containing: reviewDay).lowerBound
    }

    static func needsReview(
        reference: Date = .now,
        preferredWeekday: Weekday,
        existingReviews: [WeeklyReview],
        habits: [Habit]
    ) -> Date? {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let reviewDay = latestReviewDay(reference: referenceDay, preferredWeekday: preferredWeekday)
        guard referenceDay >= reviewDay else { return nil }

        let weekStart = AppCalendar.weekRange(containing: reviewDay).lowerBound
        let hasReview = existingReviews.contains { AppCalendar.isSameDay($0.weekStart, weekStart) }
        guard !hasReview else { return nil }

        let hasEligibleHabit = habits.contains {
            AppCalendar.startOfDay(for: $0.createdAt) < weekStart
        }
        guard hasEligibleHabit else { return nil }

        return weekStart
    }

    static func refreshReviewReminder(weekday: Weekday, hour: Int, minute: Int) async {
        await cancelReviewReminder()

        let status = await HabitReminderService.authorizationStatus()
        guard status.allowsReminderScheduling else { return }

        var dateComponents = DateComponents()
        dateComponents.calendar = AppCalendar.current
        dateComponents.timeZone = .current
        dateComponents.weekday = weekday.rawValue
        dateComponents.hour = min(max(hour, 0), 23)
        dateComponents.minute = min(max(minute, 0), 59)

        let content = UNMutableNotificationContent()
        content.title = "Tu revisión semanal"
        content.body = "Una pausa de 2 minutos: ¿qué brilló esta semana?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        try? await add(request)
    }

    static func cancelReviewReminder() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }

    private static func latestReviewDay(reference: Date, preferredWeekday: Weekday) -> Date {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let currentRaw = AppCalendar.weekday(of: referenceDay).rawValue
        let preferredRaw = preferredWeekday.rawValue
        let daysSince = (currentRaw - preferredRaw + 7) % 7
        return AppCalendar.current.date(byAdding: .day, value: -daysSince, to: referenceDay) ?? referenceDay
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
