//
//  Plan.swift
//  WeekHabit
//

import SwiftData
import Foundation

@Model
final class Plan {
    var id: UUID
    var title: String
    var motivation: String?
    var category: HabitCategory?
    var startedAt: Date
    var endsAt: Date
    var targetCompletionRate: Double
    var createdAt: Date
    var reviewedAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \Habit.plans)
    var habits: [Habit] = []

    var displayCategory: HabitCategory {
        category ?? .health
    }

    init(
        title: String,
        motivation: String? = nil,
        category: HabitCategory = .health,
        startedAt: Date = .now,
        endsAt: Date,
        targetCompletionRate: Double = 0.8,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.motivation = motivation
        self.category = category
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.targetCompletionRate = targetCompletionRate
        self.createdAt = createdAt
        self.reviewedAt = nil
    }
}
