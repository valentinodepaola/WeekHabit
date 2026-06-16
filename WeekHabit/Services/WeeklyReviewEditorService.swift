//
//  WeeklyReviewEditorService.swift
//  WeekHabit
//

import Foundation
import SwiftData

struct WeeklyReviewInput {
    let weekStart: Date
    let weekEnd: Date
    let reflectionNote: String
    let decisions: [UUID: WeeklyReviewDecisionKind]
}

struct WeeklyReviewSaveResult {
    let review: WeeklyReview?
    let pausedHabitIDs: [UUID]

    var didCreateReview: Bool {
        review != nil
    }
}

enum WeeklyReviewEditorService {
    static func save(
        input: WeeklyReviewInput,
        habits: [Habit],
        existingReviews: [WeeklyReview],
        reference: Date,
        modelContext: ModelContext
    ) throws -> WeeklyReviewSaveResult {
        let weekStart = AppCalendar.startOfDay(for: input.weekStart)
        guard !existingReviews.contains(where: { AppCalendar.isSameDay($0.weekStart, weekStart) }) else {
            return WeeklyReviewSaveResult(review: nil, pausedHabitIDs: [])
        }

        let review = WeeklyReview(
            weekStart: weekStart,
            reflectionNote: normalizedNote(input.reflectionNote)
        )

        var pausedHabitIDs: [UUID] = []

        for habit in habits {
            let kind = input.decisions[habit.id] ?? .keep
            let stats = habit.completionStats(from: weekStart, to: input.weekEnd)
            review.decisions.append(
                WeeklyReviewDecision(habit: habit, decision: kind, ratio: stats.ratio)
            )

            if kind == .pause {
                applyPause(to: habit, reference: reference)
                pausedHabitIDs.append(habit.id)
            }
        }

        modelContext.insert(review)
        try modelContext.save()

        return WeeklyReviewSaveResult(review: review, pausedHabitIDs: pausedHabitIDs)
    }

    private static func normalizedNote(_ note: String) -> String? {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? nil : note
    }

    private static func applyPause(to habit: Habit, reference: Date) {
        let start = AppCalendar.startOfDay(for: reference)
        habit.pausedUntil = AppCalendar.current.date(byAdding: .day, value: 7, to: start) ?? start
    }
}
