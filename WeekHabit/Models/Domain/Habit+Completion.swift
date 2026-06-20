//
//  Habit+Completion.swift
//  WeekHabit
//

import Foundation

extension Habit {
    var sessionTargetValue: Double {
        max(targetValuePerSession ?? 1, 1)
    }

    func isCompleted(on date: Date) -> Bool {
        totalValue(on: date) >= sessionTargetValue
    }

    func isSkipped(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.kind == .skipped
        }
    }

    func isMinimumCompleted(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.kind == .minimum
        }
    }

    func isMissed(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.kind == .missed
        }
    }

    func isSlip(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.kind == .slip
        }
    }

    func hasUrge(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.kind == .urge
        }
    }

    func slipEntry(on date: Date) -> HabitEntry? {
        entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.kind == .slip }
            .sorted { lhs, rhs in
                (lhs.completedAt ?? lhs.date) > (rhs.completedAt ?? rhs.date)
            }
            .first
    }

    var slipEntries: [HabitEntry] {
        entries
            .filter { $0.kind == .slip }
            .sorted { lhs, rhs in
                (lhs.completedAt ?? lhs.date) > (rhs.completedAt ?? rhs.date)
            }
    }

    var urgeEntries: [HabitEntry] {
        entries
            .filter { $0.kind == .urge }
            .sorted { lhs, rhs in
                (lhs.completedAt ?? lhs.date) > (rhs.completedAt ?? rhs.date)
            }
    }

    func hasAnyEntry(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.kind != .urge
        }
    }

    func totalValue(on date: Date) -> Double {
        entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.kind == .completed }
            .reduce(0) { partial, entry in
                partial + (entry.value ?? Double(entry.completedCount))
            }
    }

    func entry(on date: Date) -> HabitEntry? {
        entries.first { AppCalendar.isSameDay($0.date, date) }
    }

    /// Distinct weekdays with at least one completion within the calendar week.
    func completedWeekdays(reference: Date = .now) -> Set<Weekday> {
        let week = AppCalendar.weekRange(containing: reference)
        return Set(
            weekDays(in: week)
                .filter { isCompleted(on: $0) }
                .map { AppCalendar.weekday(of: $0) }
        )
    }

    func completedDaysThisWeek(reference: Date = .now) -> Int {
        let week = AppCalendar.weekRange(containing: reference)
        return weekDays(in: week)
            .filter { isCompleted(on: $0) }
            .count
    }

    func weekProgress(reference: Date = .now) -> Double {
        guard targetDaysPerWeek > 0 else { return 0 }
        let done = Double(completedDaysThisWeek(reference: reference))
        return min(1, done / Double(targetDaysPerWeek))
    }

    func completedDaysSince(_ startDate: Date, reference: Date = .now) -> Int {
        let calendar = AppCalendar.current
        let start = AppCalendar.startOfDay(for: startDate)
        let end = AppCalendar.startOfDay(for: reference)
        guard start <= end else { return 0 }

        var count = 0
        var cursor = start
        var scanned = 0
        while cursor <= end && scanned < 365 * 5 {
            if isCompleted(on: cursor) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            scanned += 1
        }
        return count
    }

    func expectedDaysSince(_ startDate: Date, reference: Date = .now) -> Int {
        let calendar = AppCalendar.current
        let start = AppCalendar.startOfDay(for: startDate)
        let end = AppCalendar.startOfDay(for: reference)
        guard start <= end else { return 0 }

        var count = 0
        var cursor = start
        var scanned = 0
        while cursor <= end && scanned < 365 * 5 {
            if isLoggable(on: cursor), !preservesStreakWithoutCompletion(on: cursor) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            scanned += 1
        }
        return count
    }

    func completionRatio(since startDate: Date, reference: Date = .now) -> Double {
        let expected = expectedDaysSince(startDate, reference: reference)
        guard expected > 0 else { return 0 }
        return min(1, Double(completedDaysSince(startDate, reference: reference)) / Double(expected))
    }
}
