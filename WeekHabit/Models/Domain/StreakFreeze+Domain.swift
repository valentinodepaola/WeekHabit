//
//  StreakFreeze+Domain.swift
//  WeekHabit
//

import Foundation

extension StreakFreeze {
    func matches(habit: Habit, weekContaining date: Date) -> Bool {
        habitID == habit.id
            && AppCalendar.isSameDay(weekStartDate, AppCalendar.weekRange(containing: date).lowerBound)
    }
}

extension Sequence where Element == StreakFreeze {
    func containsFreeze(for habit: Habit, weekContaining date: Date) -> Bool {
        contains { $0.matches(habit: habit, weekContaining: date) }
    }
}
