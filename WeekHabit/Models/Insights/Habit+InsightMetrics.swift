//
//  Habit+InsightMetrics.swift
//  WeekHabit
//

import Foundation

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
        let index = HabitDayIndex(self)
        var scheduled = 0
        var completed = 0

        if isFlexibleSchedule {
            var weekStart = AppCalendar.weekRange(containing: start).lowerBound
            while weekStart <= end {
                let weekEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                let visibleStart = max(max(weekStart, start), creationDay)
                let visibleEnd = min(min(weekEnd, end), endsAt.map { AppCalendar.startOfDay(for: $0) } ?? end)
                let loggableDays = visibleStart <= visibleEnd
                    ? insightDays(from: visibleStart, to: visibleEnd).filter { !index.isSkipped(on: $0) && !index.isFreezeProtected(on: $0) }
                    : []
                let weeklyTarget = min(targetDaysPerWeek, loggableDays.count)
                scheduled += weeklyTarget
                completed += min(weeklyTarget, loggableDays.filter { index.isTrustedCompleted(on: $0) }.count)

                guard let nextWeek = AppCalendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                    break
                }
                weekStart = nextWeek
            }

            return HabitCompletionStats(completed: completed, scheduled: scheduled)
        }

        for day in insightDays(from: start, to: end)
        where day >= creationDay
            && isLoggable(on: day)
            && !index.isSkipped(on: day)
            && !index.isFreezeProtected(on: day) {
            scheduled += 1
            if index.isTrustedCompleted(on: day) {
                completed += 1
            }
        }

        return HabitCompletionStats(completed: completed, scheduled: scheduled)
    }

    func weeklyDecisionSummary(
        weekStart: Date,
        activeExperiment: HabitExperiment? = nil
    ) -> WeeklyHabitSummary {
        let start = AppCalendar.startOfDay(for: weekStart)
        let end = AppCalendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        let stats = completionStats(from: start, to: end)

        return WeeklyHabitSummary(
            completionRatio: stats.ratio,
            scheduled: stats.scheduled,
            completed: stats.completed,
            dominantFailureReason: dominantFailureReason(lastDays: 7, reference: end),
            hasActiveExperiment: activeExperiment != nil
        )
    }

    func weekdayPerformance(lastDays: Int = 30, reference: Date = .now) -> [WeekdayPerformance] {
        let end = AppCalendar.startOfDay(for: reference)
        let start = AppCalendar.current.date(
            byAdding: .day,
            value: -(lastDays - 1),
            to: end
        ) ?? end

        let index = HabitDayIndex(self)

        return Weekday.ordered.map { weekday in
            var scheduled = 0
            var completed = 0

            for day in insightDays(from: start, to: end)
            where day >= AppCalendar.startOfDay(for: createdAt)
                && AppCalendar.weekday(of: day) == weekday
                && isLoggable(on: day)
                && !index.isSkipped(on: day)
                && !index.isFreezeProtected(on: day) {
                scheduled += 1
                if index.isTrustedCompleted(on: day) {
                    completed += 1
                }
            }

            return WeekdayPerformance(weekday: weekday, completed: completed, scheduled: scheduled)
        }
    }

    func peakHour(lastDays: Int = 30, reference: Date = .now) -> HourWindow? {
        let range = insightDateRange(days: lastDays, reference: reference)
        var counts: [Int: Int] = [:]

        for entry in entries where range.contains(entry.date) && entry.kind == .completed && entry.source.isTrustedForInsights {
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

    func urgeHourBuckets(lastDays: Int = 30, reference: Date = .now) -> [UrgeHourBucket] {
        let range = insightDateRange(days: lastDays, reference: reference)
        var counts: [Int: Int] = [:]

        for entry in entries where range.contains(entry.date) && entry.kind == .urge {
            guard let loggedAt = entry.completedAt else { continue }
            let hour = AppCalendar.current.component(.hour, from: loggedAt)
            counts[hour, default: 0] += 1
        }

        return (0..<24).map { hour in
            UrgeHourBucket(hour: hour, count: counts[hour, default: 0])
        }
    }

    func peakUrgeHour(lastDays: Int = 30, reference: Date = .now) -> HourWindow? {
        let buckets = urgeHourBuckets(lastDays: lastDays, reference: reference)
        guard let best = buckets.max(by: { lhs, rhs in
            if lhs.count == rhs.count { return lhs.hour > rhs.hour }
            return lhs.count < rhs.count
        }), best.count > 0 else {
            return nil
        }

        return HourWindow(startHour: best.hour, count: best.count)
    }

    func daysSinceLastCompletion(reference: Date = .now) -> Int? {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let index = HabitDayIndex(self)
        let lastDate = index.recordedDays
            .filter { $0 <= referenceDay }
            .filter { index.isTrustedCompleted(on: $0) }
            .max()

        guard let lastDate else { return nil }
        return AppCalendar.current.dateComponents([.day], from: lastDate, to: referenceDay).day
    }

    func isTrustedCompleted(on date: Date) -> Bool {
        let trustedValue = entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.kind == .completed && $0.source.isTrustedForInsights }
            .reduce(0) { partial, entry in
                partial + (entry.value ?? Double(entry.completedCount))
            }

        return trustedValue >= sessionTargetValue
    }

    func trustedMinimumDays(from startDate: Date, to endDate: Date) -> Int {
        let start = AppCalendar.startOfDay(for: startDate)
        let end = AppCalendar.startOfDay(for: endDate)
        guard start <= end else { return 0 }

        let index = HabitDayIndex(self)
        var count = 0
        for day in insightDays(from: start, to: end)
        where day >= AppCalendar.startOfDay(for: createdAt)
            && isLoggable(on: day)
            && !index.isTrustedCompleted(on: day)
            && index.hasTrustedMinimum(on: day) {
            count += 1
        }

        return count
    }

    func isManualCompleted(on date: Date) -> Bool {
        let manualValue = entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.kind == .completed && $0.source == .manual }
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
            guard entry.kind == .completed else { continue }
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

    func failureReasonCounts(lastDays: Int = 30, reference: Date = .now) -> [HabitFailureReason: Int] {
        let range = insightDateRange(days: lastDays, reference: reference)
        var counts: [HabitFailureReason: Int] = [:]

        for entry in entries where range.contains(entry.date) && entry.kind == .missed {
            guard let reason = entry.failureReasonKind else { continue }
            counts[reason, default: 0] += 1
        }

        return counts
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

    func attentionFailureType(reference: Date = .now) -> AttentionFailureType? {
        if let dominantReason = dominantFailureReason(reference: reference) {
            return .knownReason(dominantReason.reason)
        }

        let range = insightDateRange(days: 30, reference: reference)
        let index = HabitDayIndex(self)
        var notDoneCount = 0
        var manualOnlyCount = 0

        for day in insightDays(from: range.lowerBound, to: range.upperBound)
        where day >= AppCalendar.startOfDay(for: createdAt)
            && isLoggable(on: day)
            && !index.isSkipped(on: day)
            && !index.isFreezeProtected(on: day) {
            if index.isTrustedCompleted(on: day) {
                continue
            }

            if index.isManualCompleted(on: day) {
                manualOnlyCount += 1
            } else {
                notDoneCount += 1
            }
        }

        guard notDoneCount > 0 || manualOnlyCount > 0 else { return nil }
        return manualOnlyCount > notDoneCount ? .manualOnly : .notDone
    }
}
