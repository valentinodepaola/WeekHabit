//
//  Habit+Presentation.swift
//  WeekHabit
//

import Foundation

enum CellState: Equatable {
    case completed
    case minimum
    case skipped
    case frozen
    case missed
    case slip
    case urge
    case inactive
    case future
}

extension Habit {
    var unitDisplayText: String {
        if measurementUnit == .custom {
            let trimmed = customUnitName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "uds" : trimmed
        }

        return measurementUnit.shortTitle
    }

    var targetPerSessionText: String {
        guard trackingKind == .quantity else { return "check por sesión" }
        let value = Self.formattedQuantity(sessionTargetValue)
        let unit = unitDisplayText
        return unit.isEmpty ? "\(value) por sesión" : "\(value) \(unit) por sesión"
    }

    var isBreakHabit: Bool { direction == .`break` }

    var completionCTA: String {
        isBreakHabit ? "Lo evité hoy" : "Completado"
    }

    var streakLabel: String {
        isBreakHabit ? "días sin hacerlo" : "días de racha"
    }

    var breakdownCompletedLabel: String {
        isBreakHabit ? "evitado" : "hecho"
    }

    var scheduleSummaryText: String {
        switch scheduleKind {
        case .daily:
            return "Diario"
        case .specificDays:
            let days = Weekday.ordered
                .filter { activeDaysOfWeek.contains($0) }
                .map(\.shortName)
                .joined(separator: ", ")
            return days.isEmpty ? "Sin días" : days
        case .timesPerWeek:
            return isBreakHabit ? "Diario" : "\(targetDaysPerWeek) veces/sem"
        }
    }

    /// Matrix `[weeks][7]`, oldest week first and weekdays ordered L-D.
    func completionMatrix(weeks: Int, reference: Date = .now) -> [[CellState]] {
        guard weeks > 0 else { return [] }

        let calendar = AppCalendar.current
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let creationDay = AppCalendar.startOfDay(for: createdAt)
        let currentWeekStart = AppCalendar.weekRange(containing: referenceDay).lowerBound

        return (0..<weeks).map { weekIndex in
            let offset = weekIndex - (weeks - 1)
            let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)
                ?? currentWeekStart

            return Weekday.ordered.enumerated().map { dayIndex, _ in
                let date = calendar.date(byAdding: .day, value: dayIndex, to: weekStart)
                    ?? weekStart
                let day = AppCalendar.startOfDay(for: date)

                if day > referenceDay || day < creationDay {
                    return .future
                }

                if !isLoggable(on: day) {
                    return .inactive
                }

                if isCompleted(on: day) {
                    return .completed
                }

                if isMinimumCompleted(on: day) {
                    return .minimum
                }

                if isSkipped(on: day) {
                    return .skipped
                }

                if isFreezeProtected(on: day) {
                    return .frozen
                }

                if isSlip(on: day) {
                    return .slip
                }

                if isMissed(on: day) {
                    return .missed
                }

                if hasUrge(on: day) {
                    return .urge
                }

                if isFlexibleSchedule && !isCompleted(on: day) {
                    return .inactive
                }

                return .missed
            }
        }
    }

    static func formattedQuantity(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }

        return String(format: "%.1f", value)
    }
}

extension Array where Element == CellState {
    func completionRatio(target: Int) -> Double {
        guard target > 0 else { return 0 }
        let completed = filter { $0 == .completed }.count
        return Swift.min(1, Double(completed) / Double(target))
    }
}
