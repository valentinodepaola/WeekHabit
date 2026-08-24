//
//  Habit+Scheduling.swift
//  WeekHabit
//

import Foundation

extension Habit {
    var isFlexibleSchedule: Bool {
        scheduleKind == .timesPerWeek
    }

    /// True once the configured end date is in the past. The end date itself is still loggable.
    func isFinished(reference: Date = .now) -> Bool {
        guard let endsAt else { return false }
        return AppCalendar.startOfDay(for: reference) > AppCalendar.startOfDay(for: endsAt)
    }

    func isPaused(reference: Date = .now) -> Bool {
        guard let pausedUntil else { return false }
        let day = AppCalendar.startOfDay(for: reference)
        let today = AppCalendar.startOfDay(for: .now)
        return day >= today && day < AppCalendar.startOfDay(for: pausedUntil)
    }

    /// True if the habit can receive a mark on `date`.
    func isLoggable(on date: Date) -> Bool {
        let day = AppCalendar.startOfDay(for: date)
        guard day >= AppCalendar.startOfDay(for: createdAt),
              !isFinished(reference: day),
              !isPaused(reference: day) else {
            return false
        }

        return isScheduled(on: day)
    }

    /// True if the habit belongs to the day according to its schedule.
    func isScheduled(on date: Date) -> Bool {
        switch scheduleKind {
        case .daily:
            return true
        case .specificDays:
            return activeDaysOfWeek.contains(AppCalendar.weekday(of: date))
        case .timesPerWeek:
            return true
        }
    }

    /// Backward-compatible name used by views.
    func isActive(on date: Date) -> Bool {
        isLoggable(on: date)
    }

    func weekDays(in week: Range<Date>) -> [Date] {
        (0..<7).compactMap { dayOffset in
            AppCalendar.current.date(byAdding: .day, value: dayOffset, to: week.lowerBound)
        }
    }
}
