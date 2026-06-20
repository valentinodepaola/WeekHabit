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
    func recoveryPromptCandidate(before reference: Date = .now) -> RecoveryPromptCandidate? {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        guard let yesterday = AppCalendar.current.date(byAdding: .day, value: -1, to: referenceDay) else {
            return nil
        }

        guard isRecoveryPromptCandidate(on: yesterday) else {
            return nil
        }

        return RecoveryPromptCandidate(habit: self, date: yesterday, isWeeklyFlexibleMiss: false)
    }

    private func isRecoveryPromptCandidate(on date: Date) -> Bool {
        isLoggable(on: date)
            && !hasAnyEntry(on: date)
            && !isFreezeProtected(on: date)
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
