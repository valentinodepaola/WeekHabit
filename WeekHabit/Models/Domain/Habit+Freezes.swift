//
//  Habit+Freezes.swift
//  WeekHabit
//

import Foundation

extension Habit {
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

    func weeklyFreezeCandidate(reference: Date = .now) -> Date? {
        guard allowsWeeklyFreeze else { return nil }

        let referenceDay = AppCalendar.startOfDay(for: reference)
        let week = AppCalendar.weekRange(containing: referenceDay)
        guard weeklyFreeze(containing: referenceDay) == nil else { return nil }

        let index = HabitDayIndex(self)

        if isFlexibleSchedule {
            return flexibleWeeklyFreezeCandidate(in: week, referenceDay: referenceDay, index: index)
        }

        return weekDays(in: week)
            .filter { $0 < referenceDay }
            .first { isMissedFreezeCandidate(on: $0, index: index) }
    }

    private func flexibleWeeklyFreezeCandidate(
        in week: Range<Date>,
        referenceDay: Date,
        index: HabitDayIndex
    ) -> Date? {
        let weekDays = weekDays(in: week)
        let completed = weekDays.filter { index.isCompleted(on: $0) }.count
        guard completed < targetDaysPerWeek else { return nil }

        let remainingPossible = weekDays
            .filter { $0 >= referenceDay }
            .filter { isLoggable(on: $0) }
            .count

        guard completed + remainingPossible < targetDaysPerWeek else { return nil }

        return weekDays
            .filter { $0 < referenceDay }
            .first { isMissedFreezeCandidate(on: $0, index: index) }
    }

    private func isMissedFreezeCandidate(on date: Date, index: HabitDayIndex) -> Bool {
        isLoggable(on: date)
            && !index.isCompleted(on: date)
            && !index.isMinimumCompleted(on: date)
            && !index.isSkipped(on: date)
            && !index.isMissed(on: date)
            && !index.isFreezeProtected(on: date)
    }
}
