//
//  OnboardingSetupService.swift
//  WeekHabit
//

import Foundation
import SwiftData

/// Falla de persistencia del onboarding, lista para mostrarse en una alerta.
struct OnboardingSetupFailure: Identifiable {
    let id = UUID()
    let message: String
}

/// Crea y ajusta el plan inicial y sus hábitos durante el onboarding.
///
/// Las mutaciones quedan en memoria a propósito: solo `commit(modelContext:)` escribe a
/// disco, para conservar el comportamiento de guardar al terminar el paso de hábitos.
enum OnboardingSetupService {
    static let fallbackPlanTitle = "Mi semana"

    private static let planDurationInDays = 30

    /// Devuelve el plan del onboarding, reutilizando el primero existente si lo hay.
    static func ensurePlan(
        goalText: String,
        motivationText: String,
        existingPlans: [Plan],
        reference: Date = .now,
        modelContext: ModelContext
    ) -> Plan {
        let title = planTitle(from: goalText)
        let motivation = planMotivation(from: motivationText)

        if let existingPlan = existingPlans.first {
            existingPlan.title = title
            existingPlan.motivation = motivation
            return existingPlan
        }

        let plan = Plan(
            title: title,
            motivation: motivation,
            endsAt: planEndDate(from: reference)
        )
        modelContext.insert(plan)
        return plan
    }

    /// Crea el hábito de una plantilla sugerida y lo liga al plan.
    @discardableResult
    static func addHabit(
        from template: StarterHabitTemplate,
        to plan: Plan,
        modelContext: ModelContext
    ) -> Habit {
        let habit = OnboardingHabitDraft.from(template).makeHabit()
        modelContext.insert(habit)
        plan.habits.append(habit)
        return habit
    }

    /// Desliga el hábito del plan y lo elimina.
    static func removeHabit(
        _ habit: Habit,
        from plan: Plan,
        modelContext: ModelContext
    ) {
        plan.habits.removeAll { $0.id == habit.id }
        modelContext.delete(habit)
    }

    /// Escribe a disco todo lo acumulado durante el onboarding.
    static func commit(modelContext: ModelContext) throws {
        try modelContext.save()
    }

    // MARK: - Normalización

    private static func planTitle(from goalText: String) -> String {
        let trimmedGoal = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedGoal.isEmpty ? fallbackPlanTitle : trimmedGoal
    }

    private static func planMotivation(from motivationText: String) -> String? {
        let trimmedMotivation = motivationText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedMotivation.isEmpty ? nil : trimmedMotivation
    }

    private static func planEndDate(from reference: Date) -> Date {
        let endDate = AppCalendar.current.date(
            byAdding: .day,
            value: planDurationInDays,
            to: reference
        ) ?? reference

        return AppCalendar.startOfDay(for: endDate)
    }
}
