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

    /// Snapshot de la tarjeta principal de Insights para el periodo elegido.
    func insightSnapshot(for period: InsightPeriod, reference: Date = .now) -> GlobalInsightSnapshot {
        switch period {
        case .week:
            let weekStart = AppCalendar.weekRange(containing: reference).lowerBound
            return weeklySnapshot(weekStart: weekStart, reference: reference)
        case .month:
            return monthSnapshot(reference: reference)
        case .all:
            return historySnapshot(reference: reference)
        }
    }

    /// Una semana de lunes a domingo contra la anterior. Los días que todavía no llegan
    /// quedan en espera (`value == nil`). El primer día de la semana no hay comparación:
    /// un solo día contra una semana entera se movería demasiado.
    func weeklySnapshot(weekStart: Date, reference: Date = .now) -> GlobalInsightSnapshot {
        let currentStart = AppCalendar.startOfDay(for: weekStart)
        let currentEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: currentStart) ?? currentStart
        let previousStart = AppCalendar.current.date(byAdding: .day, value: -7, to: currentStart) ?? currentStart
        let previousEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: previousStart) ?? previousStart
        let visibleEnd = Swift.min(currentEnd, AppCalendar.startOfDay(for: reference))

        let current = globalCompletionStats(from: currentStart, to: visibleEnd)
        let previous = globalCompletionStats(from: previousStart, to: previousEnd)
        let hasComparison = previous.scheduled > 0 && visibleEnd > currentStart

        return GlobalInsightSnapshot(
            period: .week,
            current: current,
            comparison: hasComparison ? InsightComparison(baseline: previous, recent: current) : nil,
            trend: weeklyTrendBars(weekStart: currentStart, reference: reference),
            granularity: .day,
            range: currentStart...currentEnd,
            minimumDays: globalTrustedMinimumDays(from: currentStart, to: visibleEnd)
        )
    }

    /// Los últimos 30 días contra los 30 anteriores, en 12 tramos.
    private func monthSnapshot(reference: Date) -> GlobalInsightSnapshot {
        let currentEnd = AppCalendar.startOfDay(for: reference)
        let currentStart = AppCalendar.current.date(byAdding: .day, value: -29, to: currentEnd) ?? currentEnd
        let previousEnd = AppCalendar.current.date(byAdding: .day, value: -1, to: currentStart) ?? currentStart
        let previousStart = AppCalendar.current.date(byAdding: .day, value: -29, to: previousEnd) ?? previousEnd

        let current = globalCompletionStats(from: currentStart, to: currentEnd)
        let previous = globalCompletionStats(from: previousStart, to: previousEnd)

        var trend = globalTrendBuckets(count: 12, days: 30, reference: reference)
            .map { InsightTrendBar(value: $0) }
        if !trend.isEmpty {
            trend[0].label = "hace 30 días"
            trend[0].labelAlignment = .leading
            trend[trend.count - 1].label = "hoy"
            trend[trend.count - 1].labelAlignment = .trailing
            trend[trend.count - 1].isCurrent = true
        }

        return GlobalInsightSnapshot(
            period: .month,
            current: current,
            comparison: previous.scheduled > 0 ? InsightComparison(baseline: previous, recent: current) : nil,
            trend: trend,
            granularity: .monthSlice,
            range: currentStart...currentEnd,
            minimumDays: globalTrustedMinimumDays(from: currentStart, to: currentEnd)
        )
    }

    /// Todo el historial desde el primer hábito: una barra por semana mientras quepan
    /// `historyWeeklyBarLimit`, una por mes después, para que nunca haya cientos de barras.
    /// Compara los primeros 30 días contra los últimos 30, solo cuando no se solapan.
    private func historySnapshot(reference: Date) -> GlobalInsightSnapshot {
        let today = AppCalendar.startOfDay(for: reference)
        let firstDay = Swift.min(
            map { AppCalendar.startOfDay(for: $0.createdAt) }.min() ?? today,
            today
        )
        let dayCount = (AppCalendar.current.dateComponents([.day], from: firstDay, to: today).day ?? 0) + 1

        let weekStarts = historyWeekStarts(from: firstDay, to: today)
        let usesWeeks = weekStarts.count <= historyWeeklyBarLimit
        let trend = usesWeeks
            ? historyWeekBars(weekStarts: weekStarts, firstDay: firstDay, today: today)
            : historyMonthBars(firstDay: firstDay, today: today)

        var comparison: InsightComparison?
        if dayCount >= 60 {
            let baselineEnd = AppCalendar.current.date(byAdding: .day, value: 29, to: firstDay) ?? firstDay
            let recentStart = AppCalendar.current.date(byAdding: .day, value: -29, to: today) ?? today
            let baseline = globalCompletionStats(from: firstDay, to: baselineEnd)
            let recent = globalCompletionStats(from: recentStart, to: today)
            if baseline.scheduled > 0 && recent.scheduled > 0 {
                comparison = InsightComparison(baseline: baseline, recent: recent)
            }
        }

        return GlobalInsightSnapshot(
            period: .all,
            current: globalCompletionStats(from: firstDay, to: today),
            comparison: comparison,
            trend: trend,
            granularity: usesWeeks ? .week : .month,
            range: firstDay...today,
            minimumDays: globalTrustedMinimumDays(from: firstDay, to: today)
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

    private func weeklyTrendBars(weekStart: Date, reference: Date) -> [InsightTrendBar] {
        let referenceDay = AppCalendar.startOfDay(for: reference)

        return Weekday.ordered.enumerated().map { dayOffset, weekday in
            let day = AppCalendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            return InsightTrendBar(
                value: day <= referenceDay ? globalCompletionStats(from: day, to: day).ratio : nil,
                label: weekday.oneLetterName,
                isCurrent: day == referenceDay
            )
        }
    }

    // MARK: - Historial

    /// Más semanas que esto y el historial pasa a una barra por mes (~6 meses).
    private var historyWeeklyBarLimit: Int { 26 }

    private func historyWeekStarts(from firstDay: Date, to today: Date) -> [Date] {
        let lastWeekStart = AppCalendar.weekRange(containing: today).lowerBound
        var weekStart = AppCalendar.weekRange(containing: firstDay).lowerBound
        var weekStarts: [Date] = []

        while weekStart <= lastWeekStart {
            weekStarts.append(weekStart)
            guard let next = AppCalendar.current.date(byAdding: .day, value: 7, to: weekStart) else { break }
            weekStart = next
        }

        return weekStarts
    }

    /// Con pocas semanas cada barra lleva su fecha; con más, el mes aparece en la primera
    /// semana de cada mes, con el mismo criterio que el heatmap anual.
    private func historyWeekBars(weekStarts: [Date], firstDay: Date, today: Date) -> [InsightTrendBar] {
        var bars = weekStarts.map { weekStart in
            let weekEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let stats = globalCompletionStats(from: Swift.max(weekStart, firstDay), to: Swift.min(weekEnd, today))
            return InsightTrendBar(value: stats.ratio)
        }
        guard !bars.isEmpty else { return bars }

        if bars.count <= 4 {
            for index in bars.indices {
                bars[index].label = AppFormatters.string(from: weekStarts[index], format: "d MMM")
            }
            bars[bars.count - 1].isCurrent = true
        } else {
            let segments = HeatmapMonthSegment.segments(forWeekStarts: weekStarts)
            for (position, segment) in segments.enumerated() {
                guard let first = segment.weekIndices.first else { continue }
                bars[first].label = AppFormatters.lowercased(segment.label)
                bars[first].isCurrent = position == segments.count - 1
            }
        }

        return bars
    }

    /// Una barra por mes. Hasta 18 meses cada una lleva su inicial (en el iPhone más angosto
    /// todavía caben); con más, solo enero lleva el año, para que las etiquetas no se encimen.
    private func historyMonthBars(firstDay: Date, today: Date) -> [InsightTrendBar] {
        let calendar = AppCalendar.current
        let lastMonthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        var monthStart = calendar.dateInterval(of: .month, for: firstDay)?.start ?? firstDay
        var monthStarts: [Date] = []

        while monthStart <= lastMonthStart {
            monthStarts.append(monthStart)
            guard let next = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }
            monthStart = next
        }

        let labelsEveryMonth = monthStarts.count <= 18

        return monthStarts.enumerated().map { index, monthStart in
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            let stats = globalCompletionStats(from: Swift.max(monthStart, firstDay), to: Swift.min(monthEnd, today))
            let isLast = index == monthStarts.count - 1

            var label: String?
            if labelsEveryMonth {
                label = AppFormatters.uppercasedString(from: monthStart, format: "MMMMM")
            } else if calendar.component(.month, from: monthStart) == 1 {
                label = AppFormatters.string(from: monthStart, format: "yyyy")
            }

            return InsightTrendBar(
                value: stats.ratio,
                label: label,
                isCurrent: isLast && labelsEveryMonth
            )
        }
    }
}
