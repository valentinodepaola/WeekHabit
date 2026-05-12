//
//  StreakFreeze.swift
//  WeekHabit
//

import Foundation
import SwiftData

@Model
final class StreakFreeze {
    var id: UUID
    var usedAt: Date
    var habitID: UUID
    var weekStartDate: Date
    var protectedDate: Date
    var habit: Habit?

    init(
        habit: Habit,
        protectedDate: Date,
        usedAt: Date = .now
    ) {
        self.id = UUID()
        self.usedAt = usedAt
        self.habitID = habit.id
        self.weekStartDate = AppCalendar.weekRange(containing: protectedDate).lowerBound
        self.protectedDate = AppCalendar.startOfDay(for: protectedDate)
        self.habit = habit
    }
}
