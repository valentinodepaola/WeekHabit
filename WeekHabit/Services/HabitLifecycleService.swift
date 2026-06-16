//
//  HabitLifecycleService.swift
//  WeekHabit
//

import SwiftData

enum HabitLifecycleService {
    static func delete(
        _ habit: Habit,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(habit)
        try modelContext.save()
    }
}
