//
//  HabitEntry.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftData
import Foundation

@Model
final class HabitEntry {
    var id: UUID
    /// Normalized to `startOfDay` so range queries are timezone-stable.
    var date: Date
    /// Real timestamp for same-day marks. Retroactive marks keep this nil.
    var completedAt: Date?
    var completedCount: Int
    var habit: Habit?

    init(date: Date, completedAt: Date? = nil, completedCount: Int = 1, habit: Habit) {
        self.id = UUID()
        self.date = AppCalendar.startOfDay(for: date)
        self.completedAt = completedAt
        self.completedCount = completedCount
        self.habit = habit
    }
}
