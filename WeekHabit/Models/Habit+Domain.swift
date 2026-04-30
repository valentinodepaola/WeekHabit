//
//  Habit+Domain.swift
//  WeekHabit
//
//  Pure read-only computations over `entries` and `activeDaysOfWeek`.
//  Live in the model so `TodayView`, `WeekView`, and `InsightsView` share
//  one canonical implementation.
//

import Foundation

enum CellState: Equatable {
    case completed
    case missed
    case inactive
    case future
}

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
        var scannedDays = 0

        while scannedDays < 365 * 5 {
            if isActive(on: cursor) {
                guard isCompleted(on: cursor) else { break }
                streak += 1
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
            scannedDays += 1
        }
        return streak
    }
    
    func displayStreak(reference: Date = .now) -> Int {
        if isActive(on: reference), !isCompleted(on: reference) {
            let yesterday = AppCalendar.current.date(
                byAdding: .day,
                value: -1,
                to: AppCalendar.startOfDay(for: reference)
            ) ?? reference

            return currentStreak(reference: yesterday)
        }

        return currentStreak(reference: reference)
    }

    /// Best historical streak from the habit creation day to `reference`.
    /// Inactive days don't break the streak; missed active days do.
    func bestStreak(reference: Date = .now) -> Int {
        let calendar = AppCalendar.current
        let start = AppCalendar.startOfDay(for: createdAt)
        let end = AppCalendar.startOfDay(for: reference)
        guard start <= end else { return 0 }

        var running = 0
        var best = 0
        var cursor = start
        var scannedDays = 0

        while cursor <= end && scannedDays < 365 * 5 {
            if isActive(on: cursor) {
                if isCompleted(on: cursor) {
                    running += 1
                    best = max(best, running)
                } else {
                    running = 0
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
            scannedDays += 1
        }

        return best
    }

    /// Matrix `[weeks][7]`, oldest week first and weekdays ordered L-D.
    func completionMatrix(weeks: Int, reference: Date = .now) -> [[CellState]] {
        guard weeks > 0 else { return [] }

        let calendar = AppCalendar.current
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let creationDay = AppCalendar.startOfDay(for: createdAt)
        let currentWeekStart = AppCalendar.weekRange(containing: referenceDay).lowerBound

        return (0..<weeks).map { weekIndex in
            let offset = weekIndex - (weeks - 1)
            let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)
                ?? currentWeekStart

            return Weekday.ordered.enumerated().map { dayIndex, _ in
                let date = calendar.date(byAdding: .day, value: dayIndex, to: weekStart)
                    ?? weekStart
                let day = AppCalendar.startOfDay(for: date)

                if day > referenceDay || day < creationDay {
                    return .future
                }

                if !isActive(on: day) {
                    return .inactive
                }

                return isCompleted(on: day) ? .completed : .missed
            }
        }
    }
}
