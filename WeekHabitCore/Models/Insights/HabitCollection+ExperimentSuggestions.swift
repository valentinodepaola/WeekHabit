//
//  HabitCollection+ExperimentSuggestions.swift
//  WeekHabit
//

import Foundation

extension Sequence where Element == Habit {
    func rhythmExperimentSuggestion(
        reference: Date = .now,
        excludingHabitIDs: Set<UUID> = []
    ) -> RhythmExperimentSuggestion? {
        rhythmExperimentSuggestions(reference: reference, excludingHabitIDs: excludingHabitIDs).first?.suggestion
    }

    func rhythmExperimentSuggestions(
        reference: Date = .now,
        excludingHabitIDs: Set<UUID> = []
    ) -> [RankedRhythmSuggestion] {
        let habits = Array(self)
        guard habits.insightReadiness(reference: reference).isReady else { return [] }
        let readyHabits = habits.filter { $0.insightReadiness(reference: reference).isReady }
        let globalPeakHour = readyHabits.peakHour(reference: reference)?.startHour

        return readyHabits
            .filter { !excludingHabitIDs.contains($0.id) }
            .compactMap { habit -> RankedRhythmSuggestion? in
                let stats = habit.completionStats(reference: reference)
                guard habit.scheduleKind != .timesPerWeek,
                      stats.scheduled > 0,
                      stats.completed > 0,
                      !habit.activeDaysOfWeek.isEmpty else { return nil }

                let currentDays = Weekday.ordered.filter { habit.activeDaysOfWeek.contains($0) }
                let weekdayStats = habit.weekdayPerformance(reference: reference)
                let rankedDays = currentDays.sorted { lhs, rhs in
                    let left = weekdayStats.first { $0.weekday == lhs }
                    let right = weekdayStats.first { $0.weekday == rhs }
                    let leftRatio = left?.ratio ?? 0
                    let rightRatio = right?.ratio ?? 0

                    if leftRatio == rightRatio {
                        return (left?.completed ?? 0) > (right?.completed ?? 0)
                    }

                    return leftRatio > rightRatio
                }

                let shouldReduce = stats.ratio < 0.55 && habit.targetDaysPerWeek > 1
                let suggestedTarget = shouldReduce ? habit.targetDaysPerWeek - 1 : habit.targetDaysPerWeek
                let strongDays = rankedDays.filter { weekday in
                    let stats = weekdayStats.first { $0.weekday == weekday }
                    return (stats?.completed ?? 0) > 0
                }
                let suggestedDays = Set(strongDays.prefix(Swift.max(1, suggestedTarget)))
                let suggestedHour = habit.peakHour(reference: reference)?.startHour ?? globalPeakHour

                if shouldReduce {
                    guard !suggestedDays.isEmpty else { return nil }
                } else {
                    guard suggestedHour != nil else { return nil }
                }

                let title = shouldReduce ? "Prueba bajar la fricción" : "Prueba una hora fija"
                let message: String
                let reason: String

                if shouldReduce {
                    message = "Durante 7 días, deja \(habit.title) en \(suggestedTarget) días fuertes."
                    reason = "Tus mejores marcas aparecen en \(suggestedDays.weekdayListText)."
                } else {
                    message = "Durante 7 días, intenta \(habit.title) en tu ventana más constante."
                    reason = "La mayoría de tus marcas cae cerca de \(HourWindow(startHour: suggestedHour ?? 8, count: 0).displayText)."
                }

                let suggestion = RhythmExperimentSuggestion(
                    habit: habit,
                    title: title,
                    message: message,
                    reason: reason,
                    targetDaysPerWeek: suggestedTarget,
                    activeDays: suggestedDays.isEmpty ? habit.activeDaysOfWeek : suggestedDays,
                    suggestedStartHour: suggestedHour,
                    baselineConsistency: stats.ratio
                )

                return RankedRhythmSuggestion(
                    suggestion: suggestion,
                    priorityScore: suggestionPriorityScore(
                        habit: habit,
                        stats: stats,
                        reference: reference
                    ),
                    priorityReason: suggestionPriorityReason(
                        stats: stats,
                        confidence: habit.rhythmConfidence(reference: reference)
                    )
                )
            }
            .sorted { lhs, rhs in
                if lhs.priorityScore == rhs.priorityScore {
                    return lhs.suggestion.baselineConsistency < rhs.suggestion.baselineConsistency
                }

                return lhs.priorityScore > rhs.priorityScore
            }
    }

    private func suggestionPriorityScore(
        habit: Habit,
        stats: HabitCompletionStats,
        reference: Date
    ) -> Double {
        let consistencyGap = Swift.max(0, 1 - stats.ratio)
        let opportunity = Swift.min(1, Double(stats.scheduled) / 20)
        let confidence = habit.rhythmConfidence(reference: reference).ratio
        let daysSince = habit.daysSinceLastCompletion(reference: reference) ?? 14
        let recency = Swift.min(1, Double(daysSince) / 14)
        let timingSignal = habit.dominantFailureReason(reference: reference)?.reason == .badTiming ? 0.12 : 0

        return (consistencyGap * 0.45)
            + (opportunity * 0.25)
            + (confidence * 0.20)
            + (recency * 0.10)
            + timingSignal
    }

    private func suggestionPriorityReason(
        stats: HabitCompletionStats,
        confidence: RhythmConfidence
    ) -> String {
        if stats.ratio < 0.55 {
            return "\(stats.percentage)% de consistencia · \(AppFormatters.lowercased(confidence.title))"
        }

        return "\(stats.percentage)% de consistencia · señal horaria clara"
    }
}
