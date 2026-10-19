//
//  Habit+Presentation.swift
//  WeekHabit
//

import Foundation

/// Texto de la derecha en la fila de un completado de Hoy.
struct TodayCompletionDetail: Equatable {
    let text: String
    /// La marca vino de una sesión de ritmo: la fila lo acompaña con un reloj.
    var isFocusSession: Bool = false
}

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
        let index = HabitDayIndex(self)
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

                if index.isCompleted(on: day) {
                    return .completed
                }

                if index.isMinimumCompleted(on: day) {
                    return .minimum
                }

                if index.isSkipped(on: day) {
                    return .skipped
                }

                if index.isFreezeProtected(on: day) {
                    return .frozen
                }

                if index.isSlip(on: day) {
                    return .slip
                }

                if index.isMissed(on: day) {
                    return .missed
                }

                if index.hasUrge(on: day) {
                    return .urge
                }

                if isFlexibleSchedule && !index.isCompleted(on: day) {
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

    /// Aviso al tocar en Hoy un hábito que descansa porque ya cumplió su meta semanal. La
    /// semana siempre empieza en lunes (`AppCalendar`).
    func weeklyTargetRestNotice(reference: Date) -> String {
        "Ya cumpliste \(weeklyTargetProgressText(reference: reference)) esta semana. Vuelve a contar el lunes."
    }

    private func weeklyTargetProgressText(reference: Date) -> String {
        "\(completedDaysThisWeek(reference: reference)) de \(targetDaysPerWeek)"
    }

    /// Lo que muestra a la derecha la fila de un completado en Hoy: la hora de la marca, o
    /// por qué está en completados cuando no es una marca normal de hoy.
    func todayCompletionDetail(reference: Date) -> TodayCompletionDetail {
        let entriesForDay = entries.filter {
            AppCalendar.isSameDay($0.date, reference)
        }

        let completedEntry = entriesForDay
            .filter { $0.kind == .completed }
            .sorted { lhs, rhs in
                (lhs.completedAt ?? lhs.date) > (rhs.completedAt ?? rhs.date)
            }
            .first
        let minimumEntry = entriesForDay
            .filter { $0.kind == .minimum }
            .sorted { lhs, rhs in
                (lhs.completedAt ?? lhs.date) > (rhs.completedAt ?? rhs.date)
            }
            .first

        guard let entry = completedEntry ?? minimumEntry else {
            return TodayCompletionDetail(text: "Meta semanal · \(weeklyTargetProgressText(reference: reference))")
        }

        if entry.kind == .minimum {
            return TodayCompletionDetail(text: "Versión mínima")
        }

        // Lo registrado desde Semana no tiene una hora que valga la pena mostrar.
        if entry.source == .manual {
            return TodayCompletionDetail(text: "Registrado después")
        }

        guard let completedAt = entry.completedAt else {
            return TodayCompletionDetail(text: "Hecho", isFocusSession: entry.source == .focusSession)
        }

        return TodayCompletionDetail(
            text: AppFormatters.string(from: completedAt, format: "HH:mm"),
            isFocusSession: entry.source == .focusSession
        )
    }

    /// Avance de un hábito de cantidad que va a medias hoy ("2 de 5 min"). Sin avance, o con
    /// la meta cumplida, no hay nada que contar.
    func todayQuantityProgressText(on date: Date) -> String? {
        guard trackingKind == .quantity else { return nil }
        let total = totalValue(on: date)
        guard total > 0, total < sessionTargetValue else { return nil }

        let value = "\(Self.formattedQuantity(total)) de \(Self.formattedQuantity(sessionTargetValue))"
        let unit = unitDisplayText
        return unit.isEmpty ? value : "\(value) \(unit)"
    }

    /// Fracción del avance de cantidad de hoy, de 0 a 1, para dibujarla en la casilla.
    func todayQuantityProgress(on date: Date) -> Double {
        guard trackingKind == .quantity else { return 0 }
        return min(1, totalValue(on: date) / sessionTargetValue)
    }

    /// Copy mostrada bajo la fila de un slip registrado en Hoy.
    func todaySlipMetadata(reference: Date) -> String {
        guard let entry = slipEntry(on: reference) else {
            return "Slip registrado"
        }

        var parts: [String] = []

        if let completedAt = entry.completedAt {
            parts.append(AppFormatters.string(from: completedAt, format: "HH:mm"))
        }

        if let trigger = entry.slipTrigger {
            parts.append(trigger.title)
        }

        let trimmedContext = entry.slipContext?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedContext.isEmpty {
            parts.append(trimmedContext)
        }

        return parts.isEmpty ? "Slip registrado" : parts.joined(separator: " · ")
    }
}

extension Sequence where Element == StreakFreeze {
    /// Mensaje del banner de comodines aplicados esta semana.
    /// Espera recibir solo los freezes de la semana actual.
    func todayBannerMessage() -> String? {
        let sorted = Array(self).sorted { $0.protectedDate < $1.protectedDate }
        guard let first = sorted.first else { return nil }

        let weekday = AppCalendar.weekday(of: first.protectedDate)
            .displayName
            .lowercased(with: AppFormatters.esMXLocale)

        if sorted.count == 1 {
            return "Comodín usado el \(weekday). Tu racha sigue viva."
        }

        return "\(sorted.count) comodines usados esta semana. Tu racha sigue viva."
    }
}

extension Array where Element == CellState {
    func completionRatio(target: Int) -> Double {
        guard target > 0 else { return 0 }
        let completed = filter { $0 == .completed }.count
        return Swift.min(1, Double(completed) / Double(target))
    }
}
