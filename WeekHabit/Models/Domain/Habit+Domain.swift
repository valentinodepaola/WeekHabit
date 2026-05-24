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
    case minimum
    case skipped
    case frozen
    case missed
    case slip
    case urge
    case inactive
    case future
}

struct RecoveryPromptCandidate: Identifiable {
    let habit: Habit
    let date: Date
    let isWeeklyFlexibleMiss: Bool

    var id: String {
        "\(habit.id.uuidString)-\(date.timeIntervalSinceReferenceDate)-\(isWeeklyFlexibleMiss)"
    }
}

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
    var sessionTargetValue: Double {
        max(targetValuePerSession ?? 1, 1)
    }

    var unitDisplayText: String {
        if measurementUnit == .custom {
            let trimmed = customUnitName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "uds" : trimmed
        }

        return measurementUnit.shortTitle
    }

    var targetPerSessionText: String {
        guard trackingKind == .quantity else { return "check por sesión" }
        let value = Self.formattedQuantity(sessionTargetValue)
        let unit = unitDisplayText
        return unit.isEmpty ? "\(value) por sesión" : "\(value) \(unit) por sesión"
    }

    var isBreakHabit: Bool { direction == .`break` }

    var completionCTA: String {
        isBreakHabit ? "Lo evité hoy" : "Completado"
    }

    var streakLabel: String {
        isBreakHabit ? "días sin hacerlo" : "días de racha"
    }

    var breakdownCompletedLabel: String {
        isBreakHabit ? "evitado" : "hecho"
    }

    var scheduleSummaryText: String {
        switch scheduleKind {
        case .daily:
            return "Diario"
        case .specificDays:
            let days = Weekday.ordered
                .filter { activeDaysOfWeek.contains($0) }
                .map(\.shortName)
                .joined(separator: ", ")
            return days.isEmpty ? "Sin días" : days
        case .timesPerWeek:
            return isBreakHabit ? "Diario" : "\(targetDaysPerWeek) veces/sem"
        }
    }

    var isFlexibleSchedule: Bool {
        scheduleKind == .timesPerWeek
    }

    /// True once the configured end date is in the past. The end date itself is still loggable.
    func isFinished(reference: Date = .now) -> Bool {
        guard let endsAt else { return false }
        return AppCalendar.startOfDay(for: reference) > AppCalendar.startOfDay(for: endsAt)
    }

    /// True if the habit can receive a mark on `date`.
    func isLoggable(on date: Date) -> Bool {
        let day = AppCalendar.startOfDay(for: date)
        guard day >= AppCalendar.startOfDay(for: createdAt), !isFinished(reference: day) else {
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

    /// True if there is at least one entry on the same calendar day as `date`.
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

    func isFreezeProtected(on date: Date) -> Bool {
        guard allowsWeeklyFreeze else { return false }
        return streakFreezes.contains {
            AppCalendar.isSameDay($0.protectedDate, date)
        }
    }

    func weeklyFreeze(containing date: Date) -> StreakFreeze? {
        guard allowsWeeklyFreeze else { return nil }
        let weekStart = AppCalendar.weekRange(containing: date).lowerBound
        return streakFreezes.first {
            AppCalendar.isSameDay($0.weekStartDate, weekStart)
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

    /// Distinct weekdays with at least one entry within the calendar week containing `reference`.
    func completedWeekdays(reference: Date = .now) -> Set<Weekday> {
        let week = AppCalendar.weekRange(containing: reference)
        return Set(
            weekDays(in: week)
                .filter { isCompleted(on: $0) }
                .map { AppCalendar.weekday(of: $0) }
        )
    }

    /// Count of distinct days completed within the calendar week containing `reference`.
    func completedDaysThisWeek(reference: Date = .now) -> Int {
        let week = AppCalendar.weekRange(containing: reference)
        return weekDays(in: week)
            .filter { isCompleted(on: $0) }
            .count
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
            if isLoggable(on: cursor) {
                if isCompleted(on: cursor) {
                    streak += 1
                } else if isMinimumCompleted(on: cursor) {
                    streak += 1
                } else if !preservesStreakWithoutCompletion(on: cursor) {
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

    /// Composition of the current unbroken streak span.
    /// Completed days add evidence; skips and freezes keep the span intact without adding completion.
    func currentStreakBreakdown(reference: Date = .now) -> StreakBreakdown {
        var completedDays = 0
        var minimumDays = 0
        var skippedDays = 0
        var frozenDays = 0
        var cursor = AppCalendar.startOfDay(for: reference)
        let calendar = AppCalendar.current
        var scannedDays = 0

        while scannedDays < 365 * 5 {
            if isLoggable(on: cursor) {
                if isCompleted(on: cursor) {
                    completedDays += 1
                } else if isMinimumCompleted(on: cursor) {
                    minimumDays += 1
                } else if isSkipped(on: cursor) {
                    skippedDays += 1
                } else if isFreezeProtected(on: cursor) {
                    frozenDays += 1
                } else {
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
            if isLoggable(on: cursor) {
                if isCompleted(on: cursor) {
                    running += 1
                    best = max(best, running)
                } else if isMinimumCompleted(on: cursor) {
                    running += 1
                    best = max(best, running)
                } else if preservesStreakWithoutCompletion(on: cursor) {
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

                if !isLoggable(on: day) {
                    return .inactive
                }

                if isCompleted(on: day) {
                    return .completed
                }

                if isMinimumCompleted(on: day) {
                    return .minimum
                }

                if isSkipped(on: day) {
                    return .skipped
                }

                if isFreezeProtected(on: day) {
                    return .frozen
                }

                if isSlip(on: day) {
                    return .slip
                }

                if isMissed(on: day) {
                    return .missed
                }

                if hasUrge(on: day) {
                    return .urge
                }

                if isFlexibleSchedule && !isCompleted(on: day) {
                    return .inactive
                }

                return .missed
            }
        }
    }

    private func weekDays(in week: Range<Date>) -> [Date] {
        (0..<7).compactMap { dayOffset in
            AppCalendar.current.date(byAdding: .day, value: dayOffset, to: week.lowerBound)
        }
    }

    func weeklyFreezeCandidate(reference: Date = .now) -> Date? {
        guard allowsWeeklyFreeze else { return nil }

        let referenceDay = AppCalendar.startOfDay(for: reference)
        let week = AppCalendar.weekRange(containing: referenceDay)
        guard weeklyFreeze(containing: referenceDay) == nil else { return nil }

        if isFlexibleSchedule {
            return flexibleWeeklyFreezeCandidate(in: week, referenceDay: referenceDay)
        }

        return weekDays(in: week)
            .filter { $0 < referenceDay }
            .first { isMissedFreezeCandidate(on: $0) }
    }

    private func flexibleWeeklyFreezeCandidate(in week: Range<Date>, referenceDay: Date) -> Date? {
        let weekDays = weekDays(in: week)
        let completed = weekDays.filter { isCompleted(on: $0) }.count
        guard completed < targetDaysPerWeek else { return nil }

        let remainingPossible = weekDays
            .filter { $0 >= referenceDay }
            .filter { isLoggable(on: $0) }
            .count

        guard completed + remainingPossible < targetDaysPerWeek else { return nil }

        return weekDays
            .filter { $0 < referenceDay }
            .first { isMissedFreezeCandidate(on: $0) }
    }

    private func isMissedFreezeCandidate(on date: Date) -> Bool {
        isLoggable(on: date)
            && !isCompleted(on: date)
            && !isMinimumCompleted(on: date)
            && !isSkipped(on: date)
            && !isMissed(on: date)
            && !isFreezeProtected(on: date)
    }

    private func preservesStreakWithoutCompletion(on date: Date) -> Bool {
        isSkipped(on: date) || isFreezeProtected(on: date)
    }

    /// Días completados desde `startDate` hasta `reference` (inclusive en ambos extremos).
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

    /// Días esperados (según schedule) desde `startDate` hasta `reference`.
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

    /// Ratio 0–1 de días completados vs días esperados desde `startDate`.
    func completionRatio(since startDate: Date, reference: Date = .now) -> Double {
        let expected = expectedDaysSince(startDate, reference: reference)
        guard expected > 0 else { return 0 }
        return min(1, Double(completedDaysSince(startDate, reference: reference)) / Double(expected))
    }

    static func formattedQuantity(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }

        return String(format: "%.1f", value)
    }

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
    /// Habit with the highest current streak, or nil if none has a positive streak.
    func topStreakHabit(reference: Date = .now) -> (habit: Habit, streak: Int)? {
        self
            .map { ($0, $0.currentStreak(reference: reference)) }
            .max(by: { $0.1 < $1.1 })
            .flatMap { $0.1 > 0 ? $0 : nil }
    }

    /// True when ≥2 habits share the same positive current streak.
    func allShareSameCurrentStreak(reference: Date = .now) -> Bool {
        let streaks = map { $0.currentStreak(reference: reference) }
        guard streaks.count >= 2, let first = streaks.first, first > 0 else { return false }
        return streaks.allSatisfy { $0 == first }
    }

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

extension Array where Element == CellState {
    /// Fraction of cells completed against the weekly target, clamped to 0…1.
    func completionRatio(target: Int) -> Double {
        guard target > 0 else { return 0 }
        let completed = filter { $0 == .completed }.count
        return Swift.min(1, Double(completed) / Double(target))
    }
}
