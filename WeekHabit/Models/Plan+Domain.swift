//
//  Plan+Domain.swift
//  WeekHabit
//

import Foundation

extension Plan {

    /// True mientras la fecha de fin no ha llegado.
    func isActive(reference: Date = .now) -> Bool {
        AppCalendar.startOfDay(for: reference) <= AppCalendar.startOfDay(for: endsAt)
    }

    /// True cuando la fecha de fin ya pasó.
    func isFinished(reference: Date = .now) -> Bool {
        !isActive(reference: reference)
    }

    /// True cuando el plan terminó pero aún no fue revisado por el usuario.
    func needsReview(reference: Date = .now) -> Bool {
        isFinished(reference: reference) && reviewedAt == nil
    }

    /// Días enteros que faltan hasta la fecha de fin (0 si es hoy, negativo si ya terminó).
    func daysRemaining(reference: Date = .now) -> Int {
        let calendar = AppCalendar.current
        let today = AppCalendar.startOfDay(for: reference)
        let end = AppCalendar.startOfDay(for: endsAt)
        return calendar.dateComponents([.day], from: today, to: end).day ?? 0
    }

    /// Fracción 0–1 de completitud agregada del plan.
    /// Promedia el ratio completitud/esperado de cada hábito desde startedAt.
    func progress(reference: Date = .now) -> Double {
        guard !habits.isEmpty else { return 0 }
        let ratios = habits.map { $0.completionRatio(since: startedAt, reference: reference) }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    /// True si el progreso actual alcanza la meta configurada.
    func meetsGoal(reference: Date = .now) -> Bool {
        progress(reference: reference) >= targetCompletionRate
    }

    /// Texto descriptivo de días restantes.
    var daysRemainingText: String {
        let days = daysRemaining()
        if days < 0 { return "Terminado" }
        if days == 0 { return "Último día" }
        if days == 1 { return "1 día restante" }
        return "\(days) días restantes"
    }
}
