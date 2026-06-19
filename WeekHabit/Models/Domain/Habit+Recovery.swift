//
//  Habit+Recovery.swift
//  WeekHabit
//

import Foundation

struct RecoveryPromptCandidate: Identifiable {
    let habit: Habit
    let date: Date
    let isWeeklyFlexibleMiss: Bool

    var id: String {
        "\(habit.id.uuidString)-\(date.timeIntervalSinceReferenceDate)-\(isWeeklyFlexibleMiss)"
    }
}

extension Habit {
    func recoveryPromptCandidate(before reference: Date = .now, lookbackDays: Int = 30) -> RecoveryPromptCandidate? {
        let referenceDay = AppCalendar.startOfDay(for: reference)

        if isFlexibleSchedule {
            return flexibleRecoveryPromptCandidate(before: referenceDay, lookbackDays: lookbackDays)
        }

        guard let yesterday = AppCalendar.current.date(byAdding: .day, value: -1, to: referenceDay) else {
            return nil
        }

        var cursor = yesterday
        var scannedDays = 0

        while scannedDays < lookbackDays {
            if isRecoveryPromptCandidate(on: cursor) {
                return RecoveryPromptCandidate(habit: self, date: cursor, isWeeklyFlexibleMiss: false)
            }

            guard let previous = AppCalendar.current.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
            scannedDays += 1
        }

        return nil
    }

    private func isRecoveryPromptCandidate(on date: Date) -> Bool {
        isLoggable(on: date)
            && !hasAnyEntry(on: date)
            && !isFreezeProtected(on: date)
    }

    private func flexibleRecoveryPromptCandidate(before referenceDay: Date, lookbackDays: Int) -> RecoveryPromptCandidate? {
        let currentWeekStart = AppCalendar.weekRange(containing: referenceDay).lowerBound
        var weekStart = AppCalendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)
        var scannedWeeks = 0
        let maxWeeks = max(1, Int(ceil(Double(lookbackDays) / 7.0)))

        while let start = weekStart, scannedWeeks < maxWeeks {
            let week = start..<(AppCalendar.current.date(byAdding: .day, value: 7, to: start) ?? start)
            if let candidate = flexibleRecoveryPromptCandidate(in: week) {
                return candidate
            }

            weekStart = AppCalendar.current.date(byAdding: .weekOfYear, value: -1, to: start)
            scannedWeeks += 1
        }

        return nil
    }

    private func flexibleRecoveryPromptCandidate(in week: Range<Date>) -> RecoveryPromptCandidate? {
        let days = weekDays(in: week)
        let eligibleDays = days.filter {
            isLoggable(on: $0)
                && !isSkipped(on: $0)
                && !isFreezeProtected(on: $0)
        }
        let expected = min(targetDaysPerWeek, eligibleDays.count)
        guard expected > 0 else { return nil }

        let completed = eligibleDays.filter { isCompleted(on: $0) }.count
        guard completed < expected else { return nil }
        guard !days.contains(where: { isMissed(on: $0) }) else { return nil }
        guard let candidateDate = eligibleDays.reversed().first(where: { !hasAnyEntry(on: $0) }) else {
            return nil
        }

        return RecoveryPromptCandidate(habit: self, date: candidateDate, isWeeklyFlexibleMiss: true)
    }
}

extension Sequence where Element == Habit {
    func recoveryPromptCandidate(reference: Date = .now) -> RecoveryPromptCandidate? {
        compactMap { $0.recoveryPromptCandidate(before: reference) }
            .max { lhs, rhs in
                if AppCalendar.isSameDay(lhs.date, rhs.date) {
                    return lhs.habit.createdAt < rhs.habit.createdAt
                }

                return lhs.date < rhs.date
            }
    }
}
