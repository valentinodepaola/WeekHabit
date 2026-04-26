//
//  Habit+Domain.swift
//  WeekHabit
//
//  Pure read-only computations over `entries` and `activeDaysOfWeek`.
//  Live in the model so `TodayView`, `WeekView`, and `InsightsView` share
//  one canonical implementation.
//

import Foundation

extension Habit {
    /// True if the habit is scheduled for the weekday containing `date`.
    func isActive(on date: Date) -> Bool {
        activeDaysOfWeek.contains(AppCalendar.weekday(of: date))
    }

    /// True if there is at least one entry on the same calendar day as `date`.
    func isCompleted(on date: Date) -> Bool {
        entries.contains { AppCalendar.isSameDay($0.date, date) }
    }

    /// Count of distinct days completed within the calendar week containing `reference`.
    func completedDaysThisWeek(reference: Date = .now) -> Int {
        let week = AppCalendar.weekRange(containing: reference)
        let days = entries
            .filter { week.contains($0.date) }
            .map { AppCalendar.startOfDay(for: $0.date) }
        return Set(days).count
    }

    /// 0…1 fraction of the weekly target completed.
    func weekProgress(reference: Date = .now) -> Double {
        guard targetDaysPerWeek > 0 else { return 0 }
        let done = Double(completedDaysThisWeek(reference: reference))
        return min(1, done / Double(targetDaysPerWeek))
    }

    /// Consecutive completed-or-inactive days walking backwards from `reference`.
    /// Inactive days don't break the streak; missed active days do.
    func currentStreak(reference: Date = .now) -> Int {
        var streak = 0
        var cursor = AppCalendar.startOfDay(for: reference)
        let calendar = AppCalendar.current

        while true {
            if isActive(on: cursor) {
                guard isCompleted(on: cursor) else { break }
                streak += 1
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
            // Hard cap to avoid runaway loops on corrupted data.
            if streak > 365 * 5 { break }
        }
        return streak
    }
}
