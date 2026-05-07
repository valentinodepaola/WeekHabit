//
//  Habit+Insights.swift
//  WeekHabit
//

import Foundation

struct HabitCompletionStats {
    let completed: Int
    let scheduled: Int

    var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return min(1, Double(completed) / Double(scheduled))
    }

    var percentage: Int {
        Int((ratio * 100).rounded())
    }
}

struct GlobalInsightSnapshot {
    let current: HabitCompletionStats
    let previous: HabitCompletionStats
    let trend: [Double]

    var deltaPercentagePoints: Int {
        Int(((current.ratio - previous.ratio) * 100).rounded())
    }
}

struct InsightReadiness {
    static let defaultRequiredDays = 5
    static let defaultStableDays = 21

    let elapsedDays: Int
    let requiredDays: Int
    let stableDays: Int

    var isReady: Bool {
        elapsedDays >= requiredDays
    }

    var isStable: Bool {
        elapsedDays >= stableDays
    }

    var isProvisional: Bool {
        isReady && !isStable
    }

    var remainingDays: Int {
        max(0, requiredDays - elapsedDays)
    }

    var remainingStableDays: Int {
        max(0, stableDays - elapsedDays)
    }

    var progress: Double {
        guard requiredDays > 0 else { return 1 }
        return min(1, Double(elapsedDays) / Double(requiredDays))
    }
}

enum RhythmConfidenceLevel {
    case high
    case learning
    case low
}

struct RhythmConfidence {
    let trustedMarks: Int
    let totalMarks: Int
    let focusSessionMarks: Int

    var ratio: Double {
        guard totalMarks > 0 else { return 0 }
        return Double(trustedMarks) / Double(totalMarks)
    }

    var level: RhythmConfidenceLevel {
        guard totalMarks > 0 else { return .low }

        switch ratio {
        case 0.75...:
            return .high
        case 0.35..<0.75:
            return .learning
        default:
            return .low
        }
    }

    var title: String {
        switch level {
        case .high:
            return "Alta confianza"
        case .learning:
            return "Aún aprendiendo"
        case .low:
            return "Pocas marcas reales"
        }
    }

    var detail: String {
        guard totalMarks > 0 else {
            return "Inicia una sesión o marca desde Hoy para que Insights lea tu ritmo real."
        }

        if focusSessionMarks > 0 {
            return "\(trustedMarks) de \(totalMarks) marcas son en momento real · \(focusSessionMarks) desde sesiones."
        }

        return "\(trustedMarks) de \(totalMarks) marcas son en momento real."
    }
}

struct HabitInsightSummary: Identifiable {
    let habit: Habit
    let stats: HabitCompletionStats
    let detail: String
    var failureType: AttentionFailureType? = nil
    var recommendation: String? = nil

    var id: UUID {
        habit.id
    }
}

enum AttentionFailureType {
    case notDone
    case manualOnly

    var title: String {
        switch self {
        case .notDone:
            return "No lo hizo"
        case .manualOnly:
            return "Lo hizo manual"
        }
    }
}

struct WeekdayPerformance: Identifiable {
    let weekday: Weekday
    let completed: Int
    let scheduled: Int

    var id: Int {
        weekday.rawValue
    }

    var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return Double(completed) / Double(scheduled)
    }
}

struct HourWindow: Identifiable, Equatable {
    let startHour: Int
    let count: Int

    var id: Int {
        startHour
    }

    var endHour: Int {
        (startHour + 1) % 24
    }

    var displayText: String {
        "\(startHour):00 – \(endHour):00"
    }
}

struct RhythmExperimentSuggestion: Identifiable {
    let habit: Habit
    let title: String
    let message: String
    let reason: String
    let targetDaysPerWeek: Int
    let activeDays: Set<Weekday>
    let suggestedStartHour: Int?
    let baselineConsistency: Double

    var id: UUID {
        habit.id
    }

    var daySummary: String {
        let days = Weekday.ordered
            .filter { activeDays.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")

        return "\(targetDaysPerWeek)d/sem · \(days)"
    }

    var hourText: String? {
        guard let suggestedStartHour else { return nil }
        return HourWindow(startHour: suggestedStartHour, count: 0).displayText
    }
}

struct RankedRhythmSuggestion: Identifiable {
    let suggestion: RhythmExperimentSuggestion
    let priorityScore: Double
    let priorityReason: String

    var id: UUID {
        suggestion.id
    }
}

struct HabitInsightContext: Identifiable {
    let habit: Habit
    let count: Int

    var id: UUID {
        habit.id
    }
}

struct ContextualHourInsight: Identifiable {
    let window: HourWindow
    let habits: [HabitInsightContext]

    var id: Int {
        window.id
    }

    var contextText: String {
        habitContextText(prefix: "aplica a")
    }

    private func habitContextText(prefix: String) -> String {
        let names = habits.map { $0.habit.title }
        switch names.count {
        case 0:
            return "basada en \(window.count) marcas reales"
        case 1:
            return "\(prefix) \(names[0])"
        case 2:
            return "\(prefix) \(names.joined(separator: " y "))"
        default:
            return "\(prefix) \(names.count) hábitos, sobre todo \(names.prefix(2).joined(separator: " y "))"
        }
    }
}

struct ContextualWeekdayInsight: Identifiable {
    let performance: WeekdayPerformance
    let habits: [HabitInsightContext]

    var id: Int {
        performance.id
    }

    var contextText: String {
        let names = habits.map { $0.habit.title }
        switch names.count {
        case 0:
            return "\(Int((performance.ratio * 100).rounded()))% de cumplimiento promedio"
        case 1:
            return "\(Int((performance.ratio * 100).rounded()))% promedio · destaca \(names[0])"
        case 2:
            return "\(Int((performance.ratio * 100).rounded()))% promedio · destacan \(names.joined(separator: " y "))"
        default:
            return "\(Int((performance.ratio * 100).rounded()))% promedio · destacan \(names.prefix(2).joined(separator: " y "))"
        }
    }
}

extension Habit {
    func insightReadiness(
        requiredDays: Int = InsightReadiness.defaultRequiredDays,
        stableDays: Int = InsightReadiness.defaultStableDays,
        reference: Date = .now
    ) -> InsightReadiness {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let creationDay = AppCalendar.startOfDay(for: createdAt)
        let elapsedDays = AppCalendar.current.dateComponents([.day], from: creationDay, to: referenceDay).day ?? 0

        return InsightReadiness(
            elapsedDays: max(0, elapsedDays),
            requiredDays: requiredDays,
            stableDays: stableDays
        )
    }

    func completionStats(lastDays: Int = 30, reference: Date = .now) -> HabitCompletionStats {
        let end = AppCalendar.startOfDay(for: reference)
        let start = AppCalendar.current.date(
            byAdding: .day,
            value: -(lastDays - 1),
            to: end
        ) ?? end

        return completionStats(from: start, to: end)
    }

    func completionStats(from startDate: Date, to endDate: Date) -> HabitCompletionStats {
        let start = AppCalendar.startOfDay(for: startDate)
        let end = AppCalendar.startOfDay(for: endDate)
        guard start <= end else { return HabitCompletionStats(completed: 0, scheduled: 0) }

        let creationDay = AppCalendar.startOfDay(for: createdAt)
        var scheduled = 0
        var completed = 0

        if isFlexibleSchedule {
            var weekStart = AppCalendar.weekRange(containing: start).lowerBound
            while weekStart <= end {
                let weekEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                let visibleStart = max(max(weekStart, start), creationDay)
                let visibleEnd = min(min(weekEnd, end), endsAt.map { AppCalendar.startOfDay(for: $0) } ?? end)
                let loggableDays = visibleStart <= visibleEnd ? insightDays(from: visibleStart, to: visibleEnd) : []
                let weeklyTarget = min(targetDaysPerWeek, loggableDays.count)
                scheduled += weeklyTarget
                completed += min(weeklyTarget, loggableDays.filter { isTrustedCompleted(on: $0) }.count)

                guard let nextWeek = AppCalendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                    break
                }
                weekStart = nextWeek
            }

            return HabitCompletionStats(completed: completed, scheduled: scheduled)
        }

        for day in insightDays(from: start, to: end) where day >= creationDay && isLoggable(on: day) {
            scheduled += 1
            if isTrustedCompleted(on: day) {
                completed += 1
            }
        }

        return HabitCompletionStats(completed: completed, scheduled: scheduled)
    }

    func weekdayPerformance(lastDays: Int = 30, reference: Date = .now) -> [WeekdayPerformance] {
        let end = AppCalendar.startOfDay(for: reference)
        let start = AppCalendar.current.date(
            byAdding: .day,
            value: -(lastDays - 1),
            to: end
        ) ?? end

        return Weekday.ordered.map { weekday in
            var scheduled = 0
            var completed = 0

            for day in insightDays(from: start, to: end)
            where day >= AppCalendar.startOfDay(for: createdAt)
                && AppCalendar.weekday(of: day) == weekday
                && isLoggable(on: day) {
                scheduled += 1
                if isTrustedCompleted(on: day) {
                    completed += 1
                }
            }

            return WeekdayPerformance(weekday: weekday, completed: completed, scheduled: scheduled)
        }
    }

    func peakHour(lastDays: Int = 30, reference: Date = .now) -> HourWindow? {
        let range = insightDateRange(days: lastDays, reference: reference)
        var counts: [Int: Int] = [:]

        for entry in entries where range.contains(entry.date) && entry.source.isTrustedForInsights {
            guard let completedAt = entry.completedAt else { continue }
            let hour = AppCalendar.current.component(.hour, from: completedAt)
            counts[hour, default: 0] += 1
        }

        guard let best = counts.max(by: { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key > rhs.key }
            return lhs.value < rhs.value
        }) else {
            return nil
        }

        return HourWindow(startHour: best.key, count: best.value)
    }

    func daysSinceLastCompletion(reference: Date = .now) -> Int? {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let lastDate = entries
            .map { AppCalendar.startOfDay(for: $0.date) }
            .filter { $0 <= referenceDay }
            .filter { isTrustedCompleted(on: $0) }
            .max()

        guard let lastDate else { return nil }
        return AppCalendar.current.dateComponents([.day], from: lastDate, to: referenceDay).day
    }

    func isTrustedCompleted(on date: Date) -> Bool {
        let trustedValue = entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.source.isTrustedForInsights }
            .reduce(0) { partial, entry in
                partial + (entry.value ?? Double(entry.completedCount))
            }

        return trustedValue >= sessionTargetValue
    }

    func isManualCompleted(on date: Date) -> Bool {
        let manualValue = entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.source == .manual }
            .reduce(0) { partial, entry in
                partial + (entry.value ?? Double(entry.completedCount))
            }

        return manualValue >= sessionTargetValue
    }

    func rhythmConfidence(reference: Date = .now) -> RhythmConfidence {
        let range = insightDateRange(days: 30, reference: reference)
        var totalMarks = 0
        var trustedMarks = 0
        var focusSessionMarks = 0

        for entry in entries where range.contains(entry.date) {
            totalMarks += 1

            if entry.source.isTrustedForInsights {
                trustedMarks += 1
            }

            if entry.source == .focusSession {
                focusSessionMarks += 1
            }
        }

        return RhythmConfidence(
            trustedMarks: trustedMarks,
            totalMarks: totalMarks,
            focusSessionMarks: focusSessionMarks
        )
    }

    func attentionFailureType(reference: Date = .now) -> AttentionFailureType? {
        let range = insightDateRange(days: 30, reference: reference)
        var notDoneCount = 0
        var manualOnlyCount = 0

        for day in insightDays(from: range.lowerBound, to: range.upperBound)
        where day >= AppCalendar.startOfDay(for: createdAt) && isLoggable(on: day) {
            if isTrustedCompleted(on: day) {
                continue
            }

            if isManualCompleted(on: day) {
                manualOnlyCount += 1
            } else {
                notDoneCount += 1
            }
        }

        guard notDoneCount > 0 || manualOnlyCount > 0 else { return nil }
        return manualOnlyCount > notDoneCount ? .manualOnly : .notDone
    }
}

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
            trend: globalTrendBuckets(count: 12, days: 30, reference: reference)
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

    func attentionHabit(reference: Date = .now) -> HabitInsightSummary? {
        filter { $0.insightReadiness(reference: reference).isReady }
        .map { habit in
            let stats = habit.completionStats(reference: reference)
            let daysSince = habit.daysSinceLastCompletion(reference: reference)
            let failureType = habit.attentionFailureType(reference: reference)
            let detail: String
            let recommendation: String

            if let daysSince {
                detail = daysSince == 0 ? "marcado hoy" : "última marca hace \(daysSince) días"
            } else {
                detail = "aún sin marcas"
            }

            switch failureType {
            case .manualOnly:
                recommendation = "Se está haciendo; hagamos más fácil marcarlo en el momento."
            case .notDone:
                recommendation = "Bajemos la fricción: menos días, mejor horario o un recordatorio más amable."
            case nil:
                recommendation = "Revisa si este ritmo todavía te acompaña."
            }

            return HabitInsightSummary(
                habit: habit,
                stats: stats,
                detail: detail,
                failureType: failureType,
                recommendation: recommendation
            )
        }
        .filter { summary in
            summary.stats.scheduled > 0 && (summary.stats.ratio < 0.75 || summary.habit.displayStreak(reference: reference) == 0)
        }
        .min { lhs, rhs in
            if lhs.stats.ratio == rhs.stats.ratio {
                return lhs.stats.scheduled > rhs.stats.scheduled
            }
            return lhs.stats.ratio < rhs.stats.ratio
        }
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
                where day >= AppCalendar.startOfDay(for: habit.createdAt) && habit.isLoggable(on: day) {
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
            for entry in habit.entries where range.contains(entry.date) && entry.source.isTrustedForInsights {
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

        return (consistencyGap * 0.45)
            + (opportunity * 0.25)
            + (confidence * 0.20)
            + (recency * 0.10)
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

extension Set where Element == Weekday {
    var weekdayListText: String {
        let names = Weekday.ordered
            .filter { contains($0) }
            .map { $0.displayName.lowercased(with: Locale(identifier: "es_MX")) }

        switch names.count {
        case 0:
            return "tus días activos"
        case 1:
            return names[0]
        case 2:
            return names.joined(separator: " y ")
        default:
            return names.dropLast().joined(separator: ", ") + " y " + (names.last ?? "")
        }
    }
}

private func insightDateRange(days: Int, reference: Date) -> ClosedRange<Date> {
    let end = AppCalendar.startOfDay(for: reference)
    let start = AppCalendar.current.date(byAdding: .day, value: -(days - 1), to: end) ?? end
    return start...end
}

private func insightDays(from start: Date, to end: Date) -> [Date] {
    let startDay = AppCalendar.startOfDay(for: start)
    let endDay = AppCalendar.startOfDay(for: end)
    guard startDay <= endDay else { return [] }

    let dayCount = AppCalendar.current.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    return (0...dayCount).compactMap { offset in
        AppCalendar.current.date(byAdding: .day, value: offset, to: startDay)
    }
}
