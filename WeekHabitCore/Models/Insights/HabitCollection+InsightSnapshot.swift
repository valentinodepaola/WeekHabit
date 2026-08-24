//
//  HabitCollection+InsightSnapshot.swift
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

    func weeklySnapshot(weekStart: Date, reference: Date = .now) -> GlobalInsightSnapshot {
        let currentStart = AppCalendar.startOfDay(for: weekStart)
        let currentEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: currentStart) ?? currentStart
        let previousStart = AppCalendar.current.date(byAdding: .day, value: -7, to: currentStart) ?? currentStart
        let previousEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: previousStart) ?? previousStart
        let visibleEnd = Swift.min(currentEnd, AppCalendar.startOfDay(for: reference))

        return GlobalInsightSnapshot(
            current: globalCompletionStats(from: currentStart, to: visibleEnd),
            previous: globalCompletionStats(from: previousStart, to: previousEnd),
            trend: weeklyTrendBuckets(weekStart: currentStart, reference: reference),
            minimumDays: globalTrustedMinimumDays(from: currentStart, to: visibleEnd)
        )
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

    private func weeklyTrendBuckets(weekStart: Date, reference: Date) -> [Double] {
        let referenceDay = AppCalendar.startOfDay(for: reference)

        return (0..<7).map { dayOffset in
            let day = AppCalendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            guard day <= referenceDay else { return 0 }
            return globalCompletionStats(from: day, to: day).ratio
        }
    }
}
