//
//  WeeklyReview.swift
//  WeekHabit
//

import Foundation
import SwiftData

@Model
final class WeeklyReview {
    var id: UUID = UUID()
    var weekStart: Date
    var reviewedAt: Date
    var reflectionNote: String?

    @Relationship(deleteRule: .cascade, inverse: \WeeklyReviewDecision.review)
    var decisions: [WeeklyReviewDecision] = []

    init(weekStart: Date, reviewedAt: Date = .now, reflectionNote: String? = nil) {
        self.weekStart = AppCalendar.startOfDay(for: weekStart)
        self.reviewedAt = reviewedAt
        self.reflectionNote = reflectionNote
    }
}

@Model
final class WeeklyReviewDecision {
    var id: UUID = UUID()
    var habitID: UUID
    var habitTitle: String
    var decisionRaw: String
    var weeklyCompletionRatio: Double
    var createdAt: Date

    var review: WeeklyReview?

    init(habit: Habit, decision: WeeklyReviewDecisionKind, ratio: Double) {
        self.id = UUID()
        self.habitID = habit.id
        self.habitTitle = habit.title
        self.decisionRaw = decision.rawValue
        self.weeklyCompletionRatio = ratio
        self.createdAt = .now
    }

    var decision: WeeklyReviewDecisionKind {
        get { WeeklyReviewDecisionKind(rawValue: decisionRaw) ?? .keep }
        set { decisionRaw = newValue.rawValue }
    }
}

enum WeeklyReviewDecisionKind: String, CaseIterable, Identifiable {
    case keep
    case adjust
    case pause

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keep: return "Mantener"
        case .adjust: return "Ajustar"
        case .pause: return "Pausar"
        }
    }

    var iconName: String {
        switch self {
        case .keep: return "checkmark"
        case .adjust: return "slider.horizontal.3"
        case .pause: return "pause"
        }
    }
}
