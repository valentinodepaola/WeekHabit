//
//  HabitExperimentService.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum HabitExperimentService {
    @discardableResult
    static func start(
        suggestion: RhythmExperimentSuggestion,
        existingExperiments: [HabitExperiment],
        reference: Date = .now,
        modelContext: ModelContext
    ) throws -> HabitExperiment? {
        guard existingExperiments.activeExperiment(
            for: suggestion.habit.id,
            reference: reference
        ) == nil else {
            return nil
        }

        let experiment = HabitExperiment(
            habit: suggestion.habit,
            experimentTargetDaysPerWeek: suggestion.targetDaysPerWeek,
            experimentActiveDaysOfWeek: suggestion.activeDays,
            suggestedStartHour: suggestion.suggestedStartHour,
            baselineConsistency: suggestion.baselineConsistency,
            startedAt: reference
        )

        experiment.apply(to: suggestion.habit)
        modelContext.insert(experiment)
        try modelContext.save()

        return experiment
    }

    static func keep(
        _ experiment: HabitExperiment,
        reference: Date = .now,
        modelContext: ModelContext
    ) throws {
        experiment.keep(reference: reference)
        try modelContext.save()
    }

    static func revert(
        _ experiment: HabitExperiment,
        on habit: Habit,
        reference: Date = .now,
        modelContext: ModelContext
    ) throws {
        experiment.revert(on: habit, reference: reference)
        try modelContext.save()
    }
}
