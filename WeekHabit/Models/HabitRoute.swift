//
//  HabitRoute.swift
//  WeekHabit
//
//  Router unificado para CreateHabitView. Reemplaza TodayCreateHabitRoute,
//  TodayEditHabitRoute, DetailEditHabitRoute, InsightsEditHabitRoute.
//

import Foundation

/// Configuración inicial al crear un hábito desde una superficie específica.
struct HabitPrefill: Hashable, Identifiable {
    var initialActiveDays: Set<Weekday> = []
    var initialDaysPerWeek: Int? = nil
    var planId: UUID? = nil

    var id: String {
        let days = initialActiveDays
            .map { $0.rawValue }
            .sorted()
            .map(String.init)
            .joined(separator: ",")
        return "p-\(days)-\(initialDaysPerWeek ?? -1)-\(planId?.uuidString ?? "none")"
    }

    static let empty = HabitPrefill()
}

enum HabitRoute: Identifiable, Hashable {
    case create(prefill: HabitPrefill)
    case edit(Habit)

    var id: String {
        switch self {
        case .create(let prefill):
            return "create-\(prefill.id)"
        case .edit(let habit):
            return "edit-\(habit.id)"
        }
    }
}
