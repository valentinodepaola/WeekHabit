//
//  CreateHabitStep.swift
//  WeekHabit
//
//  Los tres pasos del formulario de hábito. El orden sigue el modelo
//  conductual (acción → ritmo → apoyos) pero separa lo obligatorio
//  (pasos 1 y 2) de lo opcional (paso 3).
//

import Foundation

enum CreateHabitStep: Int, CaseIterable, Identifiable {
    case action
    case rhythm
    case support

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .action: return "Acción"
        case .rhythm: return "Ritmo"
        case .support: return "Apoyos"
        }
    }

    var title: String {
        switch self {
        case .action: return "¿Qué quieres trabajar?"
        case .rhythm: return "¿Cuándo y cuánto?"
        case .support: return "Apoyos para sostenerlo"
        }
    }

    var subtitle: String {
        switch self {
        case .action: return "Empieza por la acción. Todo lo demás se ajusta después."
        case .rhythm: return "Define el ritmo de la semana y cómo vas a registrarlo."
        case .support: return "Todo en este paso es opcional. Suma solo lo que te sirva."
        }
    }

    var next: CreateHabitStep? {
        CreateHabitStep(rawValue: rawValue + 1)
    }

    var previous: CreateHabitStep? {
        CreateHabitStep(rawValue: rawValue - 1)
    }
}
