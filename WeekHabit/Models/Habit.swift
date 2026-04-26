//
//  Habit.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftData
import Foundation

@Model
final class Habit {
    var id: UUID
    var title: String
    var note: String?
    var category: HabitCategory
    var targetDaysPerWeek: Int
    var activeDaysOfWeekRaw: [Int]
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []

    /// Set-based view of `activeDaysOfWeekRaw`.
    var activeDaysOfWeek: Set<Weekday> {
        get { Set(activeDaysOfWeekRaw.compactMap { Weekday(rawValue: $0) }) }
        set { activeDaysOfWeekRaw = newValue.map(\.rawValue) }
    }

    init(
        title: String,
        note: String? = nil,
        category: HabitCategory,
        targetDaysPerWeek: Int,
        activeDaysOfWeek: Set<Weekday>,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.category = category
        self.targetDaysPerWeek = targetDaysPerWeek
        self.activeDaysOfWeekRaw = activeDaysOfWeek.map(\.rawValue)
        self.createdAt = createdAt
    }
}

