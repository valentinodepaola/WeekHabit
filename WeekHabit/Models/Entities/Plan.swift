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
    var startedAt: Date
    var endsAt: Date
    var targetCompletionRate: Double
    var createdAt: Date
    var reviewedAt: Date?

    var measurableOutcome: String?

    @Relationship(deleteRule: .nullify, inverse: \Habit.plans)
    var habits: [Habit] = []

    @Relationship(deleteRule: .cascade, inverse: \PlanMilestone.plan)
    var milestones: [PlanMilestone] = []

    init(
        title: String,
        motivation: String? = nil,
        measurableOutcome: String? = nil,
        startedAt: Date = .now,
        endsAt: Date,
        targetCompletionRate: Double = 0.8,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.motivation = motivation
        self.measurableOutcome = measurableOutcome
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.targetCompletionRate = targetCompletionRate
        self.createdAt = createdAt
        self.reviewedAt = nil
    }
}
