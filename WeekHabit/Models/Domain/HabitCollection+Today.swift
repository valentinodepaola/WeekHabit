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
        meetsTodaySectionTarget(on: date, index: HabitDayIndex(self))
    }

    /// Misma regla, resolviendo las consultas contra un índice ya construido.
    func meetsTodaySectionTarget(on date: Date, index: HabitDayIndex) -> Bool {
        if isFlexibleSchedule && completedDaysThisWeek(reference: date, index: index) >= targetDaysPerWeek {
            return true
        }
        return index.isCompleted(on: date) || index.isMinimumCompleted(on: date)
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

/// Las secciones de Hoy y sus contadores, resueltos en una sola pasada.
///
/// Existe porque las funciones sueltas de arriba consultan `meetsTodaySectionTarget` por
/// separado, y esa consulta llega a `completedDaysThisWeek`, que construye un
/// `HabitDayIndex` nuevo cada vez. Entre `pendingToday`, `completedToday` y
/// `completedCountToday` eso son tres índices por hábito y por pasada. Acá se construye uno
/// solo por hábito y se derivan todas las secciones de él.
///
/// Las funciones sueltas se conservan: siguen siendo la forma correcta de responder una
/// pregunta aislada, donde construir un índice saldría más caro que escanear.
struct TodayPartition {
    let pending: [Habit]
    let completed: [Habit]
    let skipped: [Habit]
    let slipped: [Habit]
    let completedCount: Int
    let activeCount: Int
    let progress: Double

    static let empty = TodayPartition(
        pending: [],
        completed: [],
        skipped: [],
        slipped: [],
        completedCount: 0,
        activeCount: 0,
        progress: 0
    )
}

extension Array where Element == Habit {
    /// Particiona los hábitos del día construyendo un solo `HabitDayIndex` por hábito.
    ///
    /// Equivale a llamar a `pendingToday`, `completedToday`, `skippedToday`, `slippedToday`,
    /// `completedCountToday`, `activeCountToday` y `dailyProgress` sobre el mismo receptor.
    /// Se espera que el receptor ya esté filtrado por `loggableToday(on:)`.
    func todayPartition(on date: Date) -> TodayPartition {
        guard !isEmpty else { return .empty }

        var pending: [Habit] = []
        var completed: [Habit] = []
        var skipped: [Habit] = []
        var slipped: [Habit] = []
        var completedCount = 0

        for habit in self {
            let index = HabitDayIndex(habit)
            let meetsTarget = habit.meetsTodaySectionTarget(on: date, index: index)
            if meetsTarget { completedCount += 1 }

            // `skipped` y `slipped` no se excluyen entre sí, igual que en las funciones
            // sueltas: son filtros independientes. Lo que sí excluyen es pendiente y
            // completado.
            let isSkipped = index.isSkipped(on: date)
            let isSlip = index.isSlip(on: date)
            if isSkipped { skipped.append(habit) }
            if isSlip { slipped.append(habit) }

            guard !isSkipped, !isSlip else { continue }
            if meetsTarget {
                completed.append(habit)
            } else {
                pending.append(habit)
            }
        }

        let activeCount = Swift.max(count - skipped.count, 0)
        let progress = activeCount > 0 ? Double(completedCount) / Double(activeCount) : 0

        return TodayPartition(
            pending: pending,
            completed: completed,
            skipped: skipped,
            slipped: slipped,
            completedCount: completedCount,
            activeCount: activeCount,
            progress: progress
        )
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
