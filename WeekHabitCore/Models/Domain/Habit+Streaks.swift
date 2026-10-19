//
//  Habit+Streaks.swift
//  WeekHabit
//

import Foundation

struct StreakBreakdown {
    let completedDays: Int
    let minimumDays: Int
    let skippedDays: Int
    let frozenDays: Int

    var protectedDays: Int {
        skippedDays + frozenDays
    }

    var totalDays: Int {
        completedDays + minimumDays + protectedDays
    }

    var hasHistory: Bool {
        totalDays > 0
    }
}

extension Habit {
    func currentStreak(reference: Date = .now) -> Int {
        streak(endingAt: reference, reference: reference)
    }

    /// Cuenta hacia atrás desde `endingAt`. `reference` es el día real de la consulta: decide
    /// qué semana sigue en curso para las agendas flexibles, aunque el conteo empiece antes.
    private func streak(endingAt start: Date, reference: Date) -> Int {
        let index = HabitDayIndex(self)
        var streak = 0
        var cursor = AppCalendar.startOfDay(for: start)
        let calendar = AppCalendar.current
        var scannedDays = 0

        while scannedDays < 365 * 5 {
            if isLoggable(on: cursor) {
                if index.isCompleted(on: cursor) {
                    streak += 1
                } else if index.isMinimumCompleted(on: cursor) {
                    streak += 1
                } else if !preservesStreak(on: cursor, reference: reference, index: index) {
                    break
                }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
            scannedDays += 1
        }
        return streak
    }

    func currentStreakBreakdown(reference: Date = .now) -> StreakBreakdown {
        let index = HabitDayIndex(self)
        var completedDays = 0
        var minimumDays = 0
        var skippedDays = 0
        var frozenDays = 0
        var cursor = AppCalendar.startOfDay(for: reference)
        let calendar = AppCalendar.current
        var scannedDays = 0

        while scannedDays < 365 * 5 {
            if isLoggable(on: cursor) {
                if index.isCompleted(on: cursor) {
                    completedDays += 1
                } else if index.isMinimumCompleted(on: cursor) {
                    minimumDays += 1
                } else if index.isSkipped(on: cursor) {
                    skippedDays += 1
                } else if index.isFreezeProtected(on: cursor) {
                    frozenDays += 1
                } else if !isCoveredByWeeklyTarget(on: cursor, reference: reference, index: index) {
                    break
                }
            }

            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
            scannedDays += 1
        }

        return StreakBreakdown(
            completedDays: completedDays,
            minimumDays: minimumDays,
            skippedDays: skippedDays,
            frozenDays: frozenDays
        )
    }

    func displayStreak(reference: Date = .now) -> Int {
        if isSlip(on: reference) {
            return 0
        }

        if isLoggable(on: reference), !isCompleted(on: reference) {
            let yesterday = AppCalendar.current.date(
                byAdding: .day,
                value: -1,
                to: AppCalendar.startOfDay(for: reference)
            ) ?? reference

            return streak(endingAt: yesterday, reference: reference)
        }

        return currentStreak(reference: reference)
    }

    func bestStreak(reference: Date = .now) -> Int {
        let calendar = AppCalendar.current
        let start = AppCalendar.startOfDay(for: createdAt)
        let end = AppCalendar.startOfDay(for: reference)
        guard start <= end else { return 0 }

        let index = HabitDayIndex(self)
        var running = 0
        var best = 0
        var cursor = start
        var scannedDays = 0

        while cursor <= end && scannedDays < 365 * 5 {
            if isLoggable(on: cursor) {
                if index.isCompleted(on: cursor) {
                    running += 1
                    best = max(best, running)
                } else if index.isMinimumCompleted(on: cursor) {
                    running += 1
                    best = max(best, running)
                } else if preservesStreak(on: cursor, reference: reference, index: index) {
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

    func preservesStreakWithoutCompletion(on date: Date) -> Bool {
        isSkipped(on: date) || isFreezeProtected(on: date)
    }

    /// En una agenda flexible la meta es de la semana, no del día: un día sin marca no rompe
    /// la racha si su semana cumplió la meta o, en la semana en curso, si todavía se puede
    /// cumplir. Una semana que terminó sin la meta sí la rompe, igual que en el resto.
    func isCoveredByWeeklyTarget(on date: Date, reference: Date, index: HabitDayIndex) -> Bool {
        guard isFlexibleSchedule else { return false }

        let completed = completedDaysThisWeek(reference: date, index: index)
        if completed >= targetDaysPerWeek { return true }

        let week = AppCalendar.weekRange(containing: date)
        let referenceDay = AppCalendar.startOfDay(for: reference)
        guard week.contains(referenceDay) else { return false }

        let remaining = weekDays(in: week)
            .filter { $0 >= referenceDay && isLoggable(on: $0) && !index.isCompleted(on: $0) }
            .count
        return completed + remaining >= targetDaysPerWeek
    }

    /// Un día sin marca que no rompe la racha: descanso, comodín o día que la meta semanal
    /// de una agenda flexible no necesitaba.
    private func preservesStreak(on date: Date, reference: Date, index: HabitDayIndex) -> Bool {
        index.preservesStreakWithoutCompletion(on: date)
            || isCoveredByWeeklyTarget(on: date, reference: reference, index: index)
    }
}

extension Sequence where Element == Habit {
    func topStreakHabit(reference: Date = .now) -> (habit: Habit, streak: Int)? {
        self
            .map { ($0, $0.currentStreak(reference: reference)) }
            .max(by: { $0.1 < $1.1 })
            .flatMap { $0.1 > 0 ? $0 : nil }
    }

    func allShareSameCurrentStreak(reference: Date = .now) -> Bool {
        let streaks = map { $0.currentStreak(reference: reference) }
        guard streaks.count >= 2, let first = streaks.first, first > 0 else { return false }
        return streaks.allSatisfy { $0 == first }
    }
}
