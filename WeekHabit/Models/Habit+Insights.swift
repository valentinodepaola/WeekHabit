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

    var id: UUID {
        habit.id
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

extension Habit {
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

        for day in insightDays(from: start, to: end) where day >= creationDay && isActive(on: day) {
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
                && isActive(on: day) {
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
            .filter { $0.source.isTrustedForInsights }
            .map { AppCalendar.startOfDay(for: $0.date) }
            .filter { $0 <= referenceDay }
            .max()

        guard let lastDate else { return nil }
        return AppCalendar.current.dateComponents([.day], from: lastDate, to: referenceDay).day
    }

    func isTrustedCompleted(on date: Date) -> Bool {
        entries.contains {
            AppCalendar.isSameDay($0.date, date) && $0.source.isTrustedForInsights
        }
    }
}

extension Sequence where Element == Habit {
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
        map { habit in
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
        map { habit in
            let stats = habit.completionStats(reference: reference)
            let daysSince = habit.daysSinceLastCompletion(reference: reference)
            let detail: String

            if let daysSince {
                detail = daysSince == 0 ? "marcado hoy" : "última marca hace \(daysSince) días"
            } else {
                detail = "aún sin marcas"
            }

            return HabitInsightSummary(habit: habit, stats: stats, detail: detail)
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

    func bestWeekday(reference: Date = .now) -> WeekdayPerformance? {
        let habits = Array(self)
        let range = insightDateRange(days: 30, reference: reference)

        return Weekday.ordered.map { weekday in
            var scheduled = 0
            var completed = 0

            for day in insightDays(from: range.lowerBound, to: range.upperBound)
            where AppCalendar.weekday(of: day) == weekday {
                for habit in habits
                where day >= AppCalendar.startOfDay(for: habit.createdAt) && habit.isActive(on: day) {
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

    func rhythmExperimentSuggestion(
        reference: Date = .now,
        excludingHabitIDs: Set<UUID> = []
    ) -> RhythmExperimentSuggestion? {
        let habits = Array(self)
        let globalPeakHour = habits.peakHour(reference: reference)?.startHour

        return habits
            .filter { !excludingHabitIDs.contains($0.id) }
            .compactMap { habit -> RhythmExperimentSuggestion? in
                let stats = habit.completionStats(reference: reference)
                guard stats.scheduled > 0, stats.completed > 0, !habit.activeDaysOfWeek.isEmpty else { return nil }

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
                let suggestedDays = Set(rankedDays.prefix(Swift.max(1, suggestedTarget)))
                let suggestedHour = habit.peakHour(reference: reference)?.startHour ?? globalPeakHour

                guard shouldReduce || suggestedHour != nil else { return nil }

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

                return RhythmExperimentSuggestion(
                    habit: habit,
                    title: title,
                    message: message,
                    reason: reason,
                    targetDaysPerWeek: suggestedTarget,
                    activeDays: suggestedDays.isEmpty ? habit.activeDaysOfWeek : suggestedDays,
                    suggestedStartHour: suggestedHour,
                    baselineConsistency: stats.ratio
                )
            }
            .min { lhs, rhs in
                lhs.baselineConsistency < rhs.baselineConsistency
            }
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
