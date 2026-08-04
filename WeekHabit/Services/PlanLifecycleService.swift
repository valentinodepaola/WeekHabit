//
//  PlanLifecycleService.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum PlanLifecycleService {
    static func delete(
        _ plan: Plan,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }

    /// Cierra el ciclo de un plan terminado: archiva los hábitos que el usuario no quiso
    /// conservar y marca el plan como revisado, en una sola transacción.
    ///
    /// Guarda de inmediato en vez de confiar en el autosave, por el mismo motivo que
    /// `HabitTrackingService.commitRecoveryMiss`: es una decisión que se toma **una sola vez**
    /// por plan. Y acá el modo de falla se realimenta — `reviewedAt == nil` es justamente la
    /// condición con la que `ContentView` decide mostrar la hoja de cierre, así que una
    /// escritura que no aterriza reabre el cierre que el usuario ya hizo, y puede dejarlo
    /// viendo hábitos que ya había archivado.
    ///
    /// Archivar es fijar `endsAt` a hoy: el hábito sigue siendo registrable hoy y deja de
    /// serlo mañana. Es lo que ya hacía la vista, sin cambios.
    static func completeWrapUp(
        _ plan: Plan,
        archiving archivedHabits: [Habit],
        reference: Date = .now,
        modelContext: ModelContext
    ) throws {
        let endDay = AppCalendar.startOfDay(for: reference)
        for habit in archivedHabits {
            habit.endsAt = endDay
        }
        plan.reviewedAt = reference

        try modelContext.save()
    }
}
