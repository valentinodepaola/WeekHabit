//
//  HabitCollection+Insights.swift
//  WeekHabit
//

import Foundation

extension Sequence where Element == Habit {
    func insightReadiness(
        requiredDays: Int = InsightReadiness.defaultRequiredDays,
        stableDays: Int = InsightReadiness.defaultStableDays,
        reference: Date = .now
    ) -> InsightReadiness {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let firstHabitDay = map { AppCalendar.startOfDay(for: $0.createdAt) }.min()
        let elapsedDays = firstHabitDay.flatMap {
            AppCalendar.current.dateComponents([.day], from: $0, to: referenceDay).day
        } ?? 0

        return InsightReadiness(
            elapsedDays: Swift.max(0, elapsedDays),
            requiredDays: requiredDays,
            stableDays: stableDays
        )
    }

    func globalInsightSnapshot(reference: Date = .now) -> GlobalInsightSnapshot {
        let currentEnd = AppCalendar.startOfDay(for: reference)
        let currentStart = AppCalendar.current.date(byAdding: .day, value: -29, to: currentEnd) ?? currentEnd
        let previousEnd = AppCalendar.current.date(byAdding: .day, value: -1, to: currentStart) ?? currentStart
        let previousStart = AppCalendar.current.date(byAdding: .day, value: -29, to: previousEnd) ?? previousEnd

        return GlobalInsightSnapshot(
            current: globalCompletionStats(from: currentStart, to: currentEnd),
            previous: globalCompletionStats(from: previousStart, to: previousEnd),
            trend: globalTrendBuckets(count: 12, days: 30, reference: reference),
            minimumDays: globalTrustedMinimumDays(from: currentStart, to: currentEnd)
        )
    }

    func topConsistentHabit(reference: Date = .now) -> HabitInsightSummary? {
        filter { $0.insightReadiness(reference: reference).isReady }
        .map { habit in
            let stats = habit.completionStats(reference: reference)
            return HabitInsightSummary(
                habit: habit,
                stats: stats,
                detail: "\(stats.percentage)% en marcas reales"
            )
        }
        .filter { $0.stats.scheduled > 0 && $0.stats.completed > 0 }
        .max { lhs, rhs in
            if lhs.stats.ratio == rhs.stats.ratio {
                return lhs.stats.completed < rhs.stats.completed
            }
            return lhs.stats.ratio < rhs.stats.ratio
        }
    }

    func rhythmConfidence(reference: Date = .now) -> RhythmConfidence {
        let range = insightDateRange(days: 30, reference: reference)
        var totalMarks = 0
        var trustedMarks = 0
        var focusSessionMarks = 0

        for habit in self {
            for entry in habit.entries where range.contains(entry.date) {
                guard entry.kind == .completed else { continue }
                totalMarks += 1

                if entry.source.isTrustedForInsights {
                    trustedMarks += 1
                }

                if entry.source == .focusSession {
                    focusSessionMarks += 1
                }
            }
        }

        return RhythmConfidence(
            trustedMarks: trustedMarks,
            totalMarks: totalMarks,
            focusSessionMarks: focusSessionMarks
        )
    }

    func failureReasonCounts(lastDays: Int = 30, reference: Date = .now) -> [HabitFailureReason: Int] {
        reduce(into: [HabitFailureReason: Int]()) { partial, habit in
            for (reason, count) in habit.failureReasonCounts(lastDays: lastDays, reference: reference) {
                partial[reason, default: 0] += count
            }
        }
    }

    func dominantFailureReason(lastDays: Int = 30, reference: Date = .now) -> DominantFailureReason? {
        let counts = failureReasonCounts(lastDays: lastDays, reference: reference)
        let total = counts.values.reduce(0, +)
        guard total > 0,
              let best = counts.max(by: { lhs, rhs in
                  if lhs.value == rhs.value {
                      return lhs.key.rawValue > rhs.key.rawValue
                  }
                  return lhs.value < rhs.value
              }),
              best.value >= 2 || total == 1 else {
            return nil
        }

        return DominantFailureReason(reason: best.key, count: best.value, total: total)
    }

    func attentionHabit(reference: Date = .now) -> HabitInsightSummary? {
        let readyHabits = filter { habit in
            habit.insightReadiness(reference: reference).isReady
        }

        let summaries = readyHabits.map { habit in
            attentionSummary(for: habit, reference: reference)
        }

        let candidates = summaries.filter { summary in
            isAttentionCandidate(summary, reference: reference)
        }

        return candidates.min { lhs, rhs in
            isHigherAttentionPriority(lhs, than: rhs)
        }
    }

    private func attentionSummary(for habit: Habit, reference: Date) -> HabitInsightSummary {
        let stats = habit.completionStats(reference: reference)
        let daysSince = habit.daysSinceLastCompletion(reference: reference)
        let failureType = habit.attentionFailureType(reference: reference)

        return HabitInsightSummary(
            habit: habit,
            stats: stats,
            detail: attentionDetail(daysSince: daysSince),
            failureType: failureType,
            recommendation: attentionRecommendation(for: failureType)
        )
    }

    private func attentionDetail(daysSince: Int?) -> String {
        guard let daysSince else {
            return "aún sin marcas"
        }

        if daysSince == 0 {
            return "marcado hoy"
        }

        return "última marca hace \(daysSince) días"
    }

    private func attentionRecommendation(for failureType: AttentionFailureType?) -> String {
        switch failureType {
        case .knownReason(let reason):
            return recommendation(for: reason)
        case .manualOnly:
            return "Se está haciendo; hagamos más fácil marcarlo en el momento."
        case .notDone:
            return "Bajemos la fricción: menos días, mejor horario o un recordatorio más amable."
        case nil:
            return "Revisa si este ritmo todavía te acompaña."
        }
    }

    private func isAttentionCandidate(_ summary: HabitInsightSummary, reference: Date) -> Bool {
        guard summary.stats.scheduled > 0 else { return false }
        if summary.stats.ratio < 0.75 { return true }
        return summary.habit.displayStreak(reference: reference) == 0
    }

    private func isHigherAttentionPriority(
        _ lhs: HabitInsightSummary,
        than rhs: HabitInsightSummary
    ) -> Bool {
        if lhs.stats.ratio == rhs.stats.ratio {
            return lhs.stats.scheduled > rhs.stats.scheduled
        }

        return lhs.stats.ratio < rhs.stats.ratio
    }

    func contextualBestWeekday(reference: Date = .now) -> ContextualWeekdayInsight? {
        guard let best = bestWeekday(reference: reference) else { return nil }
        let range = insightDateRange(days: 30, reference: reference)
        var contexts: [HabitInsightContext] = []

        for habit in self {
            var completed = 0
            for day in insightDays(from: range.lowerBound, to: range.upperBound)
            where day >= AppCalendar.startOfDay(for: habit.createdAt)
                && AppCalendar.weekday(of: day) == best.weekday
                && habit.isLoggable(on: day)
                && habit.isTrustedCompleted(on: day) {
                completed += 1
            }

            if completed > 0 {
                contexts.append(HabitInsightContext(habit: habit, count: completed))
            }
        }

        return ContextualWeekdayInsight(
            performance: best,
            habits: contexts.sorted { $0.count > $1.count }
        )
    }

    func bestWeekday(reference: Date = .now) -> WeekdayPerformance? {
        let habits = Array(self)
        let range = insightDateRange(days: 30, reference: reference)

        return Weekday.ordered.map { weekday in
            var scheduled = 0
            var completed = 0

            for day in insightDays(from: range.lowerBound, to: range.upperBound)
            where AppCalendar.weekday(of: day) == weekday {
                for habit in habits
                where day >= AppCalendar.startOfDay(for: habit.createdAt)
                    && habit.isLoggable(on: day)
                    && !habit.isSkipped(on: day)
                    && !habit.isFreezeProtected(on: day) {
                    scheduled += 1
                    if habit.isTrustedCompleted(on: day) {
                        completed += 1
                    }
                }
            }

            return WeekdayPerformance(weekday: weekday, completed: completed, scheduled: scheduled)
        }
        .filter { $0.scheduled > 0 }
        .max { lhs, rhs in
            if lhs.ratio == rhs.ratio {
                return lhs.completed < rhs.completed
            }
            return lhs.ratio < rhs.ratio
        }
    }

    func peakHour(reference: Date = .now) -> HourWindow? {
        let range = insightDateRange(days: 30, reference: reference)
        var counts: [Int: Int] = [:]

        for habit in self {
            for entry in habit.entries where range.contains(entry.date) && entry.kind == .completed && entry.source.isTrustedForInsights {
                guard let completedAt = entry.completedAt else { continue }
                let hour = AppCalendar.current.component(.hour, from: completedAt)
                counts[hour, default: 0] += 1
            }
        }

        guard let best = counts.max(by: { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key > rhs.key }
            return lhs.value < rhs.value
        }) else {
            return nil
        }

        return HourWindow(startHour: best.key, count: best.value)
    }

    func contextualPeakHour(reference: Date = .now) -> ContextualHourInsight? {
        guard let window = peakHour(reference: reference) else { return nil }
        let range = insightDateRange(days: 30, reference: reference)
        var contexts: [HabitInsightContext] = []

        for habit in self {
            let count = habit.entries.filter { entry in
                guard range.contains(entry.date),
                      entry.kind == .completed,
                      entry.source.isTrustedForInsights,
                      let completedAt = entry.completedAt else {
                    return false
                }

                return AppCalendar.current.component(.hour, from: completedAt) == window.startHour
            }.count

            if count > 0 {
                contexts.append(HabitInsightContext(habit: habit, count: count))
            }
        }

        return ContextualHourInsight(
            window: window,
            habits: contexts.sorted { $0.count > $1.count }
        )
    }

    func urgeHourBuckets(reference: Date = .now) -> [UrgeHourBucket] {
        let range = insightDateRange(days: 30, reference: reference)
        var counts: [Int: Int] = [:]

        for habit in self where habit.isBreakHabit {
            for entry in habit.entries where range.contains(entry.date) && entry.kind == .urge {
                guard let loggedAt = entry.completedAt else { continue }
                let hour = AppCalendar.current.component(.hour, from: loggedAt)
                counts[hour, default: 0] += 1
            }
        }

        return (0..<24).map { hour in
            UrgeHourBucket(hour: hour, count: counts[hour, default: 0])
        }
    }

    func urgePeakHourInsight(reference: Date = .now, minimumCount: Int = 3) -> UrgePeakHourInsight? {
        let buckets = urgeHourBuckets(reference: reference)
        let total = buckets.reduce(0) { $0 + $1.count }

        guard total >= minimumCount,
              let best = buckets.max(by: { lhs, rhs in
                  if lhs.count == rhs.count { return lhs.hour > rhs.hour }
                  return lhs.count < rhs.count
              }),
              best.count > 0 else {
            return nil
        }

        let range = insightDateRange(days: 30, reference: reference)
        var contexts: [HabitInsightContext] = []

        for habit in self where habit.isBreakHabit {
            let count = habit.entries.filter { entry in
                guard range.contains(entry.date),
                      entry.kind == .urge,
                      let loggedAt = entry.completedAt else {
                    return false
                }

                return AppCalendar.current.component(.hour, from: loggedAt) == best.hour
            }.count

            if count > 0 {
                contexts.append(HabitInsightContext(habit: habit, count: count))
            }
        }

        return UrgePeakHourInsight(
            window: HourWindow(startHour: best.hour, count: best.count),
            totalCount: total,
            habits: contexts.sorted { $0.count > $1.count }
        )
    }

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

    private func recommendation(for reason: HabitFailureReason) -> String {
        switch reason {
        case .tooDifficult:
            return "Se está sintiendo pesado; bajemos la fricción o reduzcamos la meta por una semana."
        case .forgot:
            return "El patrón apunta a olvido; conviene atarlo a una señal o activar un recordatorio amable."
        case .badTiming:
            return "El horario parece estar estorbando; probemos una ventana más realista."
        case .lowEnergy:
            return "Suele fallar por energía; muévelo a un momento más ligero o reduce la carga."
        case .other:
            return "Hay una razón repetida; revisa si el ritmo todavía acompaña tu semana."
        }
    }

    private func suggestionPriorityReason(
        stats: HabitCompletionStats,
        confidence: RhythmConfidence
    ) -> String {
        if stats.ratio < 0.55 {
            return "\(stats.percentage)% de consistencia · \(confidence.title.lowercased(with: Locale(identifier: "es_MX")))"
        }

        return "\(stats.percentage)% de consistencia · señal horaria clara"
    }

    private func globalCompletionStats(from start: Date, to end: Date) -> HabitCompletionStats {
        reduce(HabitCompletionStats(completed: 0, scheduled: 0)) { partial, habit in
            let stats = habit.completionStats(from: start, to: end)
            return HabitCompletionStats(
                completed: partial.completed + stats.completed,
                scheduled: partial.scheduled + stats.scheduled
            )
        }
    }

    private func globalTrustedMinimumDays(from start: Date, to end: Date) -> Int {
        reduce(0) { partial, habit in
            partial + habit.trustedMinimumDays(from: start, to: end)
        }
    }

    private func globalTrendBuckets(count: Int, days: Int, reference: Date) -> [Double] {
        guard count > 0, days > 0 else { return [] }

        let end = AppCalendar.startOfDay(for: reference)
        let start = AppCalendar.current.date(byAdding: .day, value: -(days - 1), to: end) ?? end

        return (0..<count).map { index in
            let bucketStartOffset = Int((Double(index) * Double(days) / Double(count)).rounded(.down))
            let bucketEndOffset = Int((Double(index + 1) * Double(days) / Double(count)).rounded(.down)) - 1
            let bucketStart = AppCalendar.current.date(byAdding: .day, value: bucketStartOffset, to: start) ?? start
            let bucketEnd = AppCalendar.current.date(byAdding: .day, value: bucketEndOffset, to: start) ?? bucketStart
            return globalCompletionStats(from: bucketStart, to: bucketEnd).ratio
        }
    }
}
