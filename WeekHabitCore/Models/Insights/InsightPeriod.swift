//
//  InsightPeriod.swift
//  WeekHabit
//

import Foundation

/// Periodo que lee la tarjeta principal de Insights. Se guarda con `@AppStorage`, así que
/// el `rawValue` es parte de lo persistido: no se renombra.
enum InsightPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case all

    static let storageKey = "insightsHeroPeriod"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Semana"
        case .month: return "Mes"
        case .all: return "Todo"
        }
    }
}

/// Qué representa cada barra de la gráfica.
enum InsightTrendGranularity: Equatable {
    /// Un día de la semana (Semana).
    case day
    /// Un tramo de los últimos 30 días (Mes).
    case monthSlice
    /// Una semana del historial (Todo, historial corto).
    case week
    /// Un mes del historial (Todo, historial largo).
    case month
}

/// Una barra de la gráfica con su etiqueta ya resuelta.
struct InsightTrendBar: Equatable {
    enum LabelAlignment: Equatable {
        case leading
        case center
        case trailing
    }

    /// Cumplimiento entre 0 y 1. `nil` es un día que todavía no llega: se dibuja en espera,
    /// nunca como un cero que se leería como un día fallido.
    let value: Double?
    var label: String? = nil
    var labelAlignment: LabelAlignment = .center
    /// Marca la etiqueta del momento actual (hoy, esta semana, este mes).
    var isCurrent: Bool = false

    var isPending: Bool { value == nil }
}

/// Las dos tasas que compara el chip de la tarjeta: `recent` contra `baseline`.
struct InsightComparison: Equatable {
    let baseline: HabitCompletionStats
    let recent: HabitCompletionStats

    var deltaPercentagePoints: Int {
        Int(((recent.ratio - baseline.ratio) * 100).rounded())
    }
}
