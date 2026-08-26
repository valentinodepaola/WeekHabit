//
//  YearHeatmapCopy.swift
//  WeekHabitWidgets
//

import Foundation

/// Todo el texto del widget "Año de constancia", en un solo lugar.
///
/// Misma regla que `TodayWidgetCopy`: el copy no se incrusta en la vista, y el tono no
/// reprocha. Un año con poca constancia se cuenta como un dato, no como un veredicto, y
/// siempre deja algo hacia adelante.
enum YearHeatmapCopy {

    static let eyebrow = "AÑO DE CONSTANCIA"

    static func headline(for snapshot: YearHeatmapSnapshot) -> String {
        guard snapshot.hasAnyHabit else { return "Tu primer hábito" }
        return "\(percent(snapshot.completionRate)) de constancia"
    }

    static func detail(for snapshot: YearHeatmapSnapshot) -> String {
        guard snapshot.hasAnyHabit else {
            return "Créalo y este mapa se llena solo, un cuadro por día."
        }

        switch snapshot.perfectDays {
        case 0:
            return "Aún ningún día con todo hecho. Va a llegar."
        case 1:
            return "1 día con todo hecho en el último año."
        default:
            return "\(snapshot.perfectDays) días con todo hecho en el último año."
        }
    }

    /// Etiquetas de la leyenda de intensidad, al estilo GitHub.
    static let legendLess = "menos"
    static let legendMore = "más"

    static func accessibilityLabel(for snapshot: YearHeatmapSnapshot) -> String {
        guard snapshot.hasAnyHabit else {
            return "Aún no hay hábitos. El mapa del año se llena al crear el primero."
        }

        return "Constancia de las últimas \(snapshot.weeks.count) semanas: "
            + "\(percent(snapshot.completionRate)) de cumplimiento, "
            + "\(snapshot.perfectDays) días con todo hecho."
    }

    private static func percent(_ ratio: Double) -> String {
        "\(Int((ratio * 100).rounded()))%"
    }
}
