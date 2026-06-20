//
//  HabitCollection+Today.swift
//  WeekHabit
//

import Foundation

extension Habit {
    /// Considera al hábito como "hecho" para las secciones de Hoy:
    /// para agendas flexibles, basta con cumplir la meta semanal; en el
    /// resto, debe estar completado o marcado con versión mínima ese día.
    func meetsTodaySectionTarget(on date: Date) -> Bool {
        if isFlexibleSchedule && completedDaysThisWeek(reference: date) >= targetDaysPerWeek {
            return true
        }
        return isCompleted(on: date) || isMinimumCompleted(on: date)
    }
}

extension Sequence where Element == Habit {
    /// Hábitos que pueden registrarse hoy según su agenda.
    func loggableToday(on date: Date) -> [Habit] {
        filter { $0.isLoggable(on: date) }
    }
}

extension Array where Element == Habit {
    /// Hábitos del día sin marca de completado, descanso ni slip.
    /// Se espera que el receptor ya esté filtrado por `loggableToday(on:)`.
    func pendingToday(on date: Date) -> [Habit] {
        filter {
            !$0.meetsTodaySectionTarget(on: date)
                && !$0.isSkipped(on: date)
                && !$0.isSlip(on: date)
        }
    }

    /// Hábitos del día completados (o con versión mínima / meta semanal cumplida).
    func completedToday(on date: Date) -> [Habit] {
        filter {
            $0.meetsTodaySectionTarget(on: date)
                && !$0.isSkipped(on: date)
                && !$0.isSlip(on: date)
        }
    }

    /// Hábitos del día marcados como descanso.
    func skippedToday(on date: Date) -> [Habit] {
        filter { $0.isSkipped(on: date) }
    }

    /// Hábitos del día con slip registrado.
    func slippedToday(on date: Date) -> [Habit] {
        filter { $0.isSlip(on: date) }
    }

    /// Conteo de hábitos del día con `meetsTodaySectionTarget` verdadero.
    func completedCountToday(on date: Date) -> Int {
        filter { $0.meetsTodaySectionTarget(on: date) }.count
    }

    /// Hábitos activos (no en descanso) contados para el progreso del día.
    func activeCountToday(on date: Date) -> Int {
        Swift.max(count - skippedToday(on: date).count, 0)
    }

    /// Progreso del día como ratio completados / activos.
    func dailyProgress(on date: Date) -> Double {
        let active = activeCountToday(on: date)
        guard active > 0 else { return 0 }
        return Double(completedCountToday(on: date)) / Double(active)
    }
}

extension Sequence where Element == StreakFreeze {
    /// Filtra freezes de la semana de `reference` para el conjunto de hábitos dado.
    func usedInWeek(of reference: Date, habitIDs: Set<UUID>) -> [StreakFreeze] {
        let weekStart = AppCalendar.weekRange(containing: reference).lowerBound
        return filter { habitIDs.contains($0.habitID) && AppCalendar.isSameDay($0.weekStartDate, weekStart) }
            .sorted { $0.protectedDate < $1.protectedDate }
    }
}
