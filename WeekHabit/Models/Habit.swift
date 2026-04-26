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
    var category: String        // String libre, el usuario define
    var targetDaysPerWeek: Int
    var activeDaysOfWeekRaw: [Int]  // almacenado como [Int]
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []

    // Interfaz cómoda para trabajar con Weekday
    var activeDaysOfWeek: Set<Weekday> {
        get { Set(activeDaysOfWeekRaw.compactMap { Weekday(rawValue: $0) }) }
        set { activeDaysOfWeekRaw = newValue.map(\.rawValue) }
    }
    
    var habitCategory: HabitCategory {
        HabitCategory(rawValue: category) ?? .personal
    }

    init(
        title: String,
        note: String? = nil,
        category: String,
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

