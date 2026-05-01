//
//  HabitExperiment+Domain.swift
//  WeekHabit
//

import Foundation

extension HabitExperiment {
    func isActive(reference: Date = .now) -> Bool {
        status == .active && reference < endsAt
    }

    func needsReview(reference: Date = .now) -> Bool {
        status == .active && reference >= endsAt
    }

    var isResolved: Bool {
        status != .active
    }

    var suggestedHourText: String? {
        guard let suggestedStartHour else { return nil }
        return HourWindow(startHour: suggestedStartHour, count: 0).displayText
    }

    var daySummary: String {
        let days = Weekday.ordered
            .filter { experimentActiveDaysOfWeek.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
        return "\(experimentTargetDaysPerWeek)d/sem · \(days)"
    }

    func daysRemaining(reference: Date = .now) -> Int {
        guard status == .active else { return 0 }
        let start = AppCalendar.startOfDay(for: reference)
        let end = AppCalendar.startOfDay(for: endsAt)
        let days = AppCalendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days, 0)
    }

    func apply(to habit: Habit) {
        habit.targetDaysPerWeek = experimentTargetDaysPerWeek
        habit.activeDaysOfWeek = experimentActiveDaysOfWeek
        habitTitle = habit.title
    }

    func keep(reference: Date = .now) {
        status = .kept
        resolvedAt = reference
    }

    func revert(on habit: Habit, reference: Date = .now) {
        habit.targetDaysPerWeek = originalTargetDaysPerWeek
        habit.activeDaysOfWeek = originalActiveDaysOfWeek
        status = .reverted
        resolvedAt = reference
    }

    func cancel(reference: Date = .now) {
        status = .cancelled
        resolvedAt = reference
    }

    func currentConsistency(for habit: Habit, reference: Date = .now) -> Double {
        let end = min(reference, endsAt)
        return habit.completionStats(from: startedAt, to: end).ratio
    }
}

extension Sequence where Element == HabitExperiment {
    func activeExperiment(for habitID: UUID, reference: Date = .now) -> HabitExperiment? {
        first { $0.habitID == habitID && ($0.isActive(reference: reference) || $0.needsReview(reference: reference)) }
    }

    func activeHabitIDs(reference: Date = .now) -> Set<UUID> {
        Set(
            filter { $0.isActive(reference: reference) || $0.needsReview(reference: reference) }
                .map(\.habitID)
        )
    }
}
