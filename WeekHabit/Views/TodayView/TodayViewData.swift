//
//  TodayViewData.swift
//  WeekHabit
//

import Foundation

/// Todos los datos derivados que `TodayView` necesita para un render, calculados **una sola
/// vez** a partir de los resultados de `@Query`.
///
/// Antes cada derivado era una propiedad computada que volvía a llamar a `loggableToday` y a
/// particionar; entre los nueve derivados y la firma de animación eran unas 15 pasadas por
/// render, y cada partición construía su propio `HabitDayIndex` por hábito. Acá se recorre
/// una vez y se comparte el índice vía `todayPartition(on:)`.
///
/// Es un value type a propósito: se testea sin levantar una vista.
struct TodayViewData {
    let todayHabits: [Habit]
    let partition: TodayPartition
    let focusCandidateHabits: [Habit]
    let weeklyFreezes: [StreakFreeze]
    let tomorrowHabitsCount: Int
    let weeklyReviewWeekStart: Date?
    /// Hábitos que ayer quedaron sin marcar. Lo consumen la auto-presentación de la hoja de
    /// recuperación, el banner de reentrada y la semilla del roster de esa hoja.
    let recoveryCandidates: [RecoveryPromptCandidate]
    /// Identidad de las secciones, para animar solo cuando un hábito cambia de lugar.
    let sectionSignature: String

    var isEmpty: Bool { todayHabits.isEmpty }
    var remainingCount: Int { partition.pending.count }
    var hasFocusCandidates: Bool { !focusCandidateHabits.isEmpty }

    init(
        habits: [Habit],
        streakFreezes: [StreakFreeze],
        weeklyReviews: [WeeklyReview],
        weeklyReviewWeekday: Weekday,
        referenceDate: Date
    ) {
        let todayHabits = habits.loggableToday(on: referenceDate)
        let partition = todayHabits.todayPartition(on: referenceDate)
        self.todayHabits = todayHabits
        self.partition = partition

        // Se filtra sobre `todayHabits` y no sobre `pending + completed` para conservar el
        // orden original: la sesión de enfoque los recorre en secuencia.
        let unavailableIDs = Set(partition.skipped.map(\.id))
            .union(partition.slipped.map(\.id))
        self.focusCandidateHabits = todayHabits.filter { !unavailableIDs.contains($0.id) }

        let freezableIDs = Set(todayHabits.filter(\.allowsWeeklyFreeze).map(\.id))
        let weeklyFreezes = streakFreezes.usedInWeek(of: referenceDate, habitIDs: freezableIDs)
        self.weeklyFreezes = weeklyFreezes

        let tomorrow = AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate)
            ?? referenceDate
        self.tomorrowHabitsCount = habits.loggableToday(on: tomorrow).count

        // Se calcula sobre `habits` y no sobre `todayHabits`: la agenda de ayer puede no ser la
        // de hoy, y un hábito que hoy no toca pudo quedar pendiente ayer.
        self.recoveryCandidates = habits.recoveryPromptCandidates(reference: referenceDate)

        self.weeklyReviewWeekStart = WeeklyReviewService.needsReview(
            reference: referenceDate,
            preferredWeekday: weeklyReviewWeekday,
            existingReviews: weeklyReviews,
            habits: habits
        )

        self.sectionSignature = Self.signature(partition: partition, freezes: weeklyFreezes)
    }

    private static func signature(partition: TodayPartition, freezes: [StreakFreeze]) -> String {
        let pending = partition.pending.map { "p:\($0.id.uuidString)" }
        let completed = partition.completed.map { "c:\($0.id.uuidString)" }
        let skipped = partition.skipped.map { "s:\($0.id.uuidString)" }
        let slipped = partition.slipped.map { "sl:\($0.id.uuidString)" }
        let freezes = freezes.map { "f:\($0.id.uuidString)" }
        return (pending + completed + skipped + slipped + freezes).joined(separator: "|")
    }
}
