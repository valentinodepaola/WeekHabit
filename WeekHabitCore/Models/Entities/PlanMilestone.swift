//
//  PlanMilestone.swift
//  WeekHabit
//

import SwiftData
import Foundation

@Model
final class PlanMilestone {
    var id: UUID
    var title: String
    var targetDate: Date
    var completedAt: Date?
    var createdAt: Date
    var plan: Plan?

    init(title: String, targetDate: Date, plan: Plan) {
        self.id = UUID()
        self.title = title
        self.targetDate = AppCalendar.startOfDay(for: targetDate)
        self.completedAt = nil
        self.createdAt = .now
        self.plan = plan
    }
}
