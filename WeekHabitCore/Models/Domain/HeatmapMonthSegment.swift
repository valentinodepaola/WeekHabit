//
//  HeatmapMonthSegment.swift
//  WeekHabit
//

import Foundation

/// Un tramo de semanas consecutivas que caen en el mismo mes, con su etiqueta ya resuelta.
///
/// Existe para que el heatmap anual de la app (`LastWeeksHeatmapCard`) y el widget "Año de
/// constancia" agrupen las semanas por mes con el mismo criterio: decidir a qué mes pertenece
/// una semana a caballo entre dos, y encadenar los tramos, es la única parte no trivial del
/// layout. Vive una sola vez y se prueba una sola vez; antes era lógica privada de la vista.
struct HeatmapMonthSegment: Identifiable, Equatable {
    /// Clave estable "año-mes" (p. ej. `"2026-6"`). Sirve de `id` para `ForEach`.
    let id: String
    /// Nombre corto del mes en mayúsculas y en español (p. ej. `"JUN"`).
    let label: String
    /// Índices —dentro del arreglo de `weekStarts` recibido— de las semanas de este mes.
    let weekIndices: [Int]
}

extension HeatmapMonthSegment {
    /// Agrupa `weekStarts` en tramos consecutivos por mes, en el mismo orden recibido.
    ///
    /// El mes de una semana lo decide su cuarto día (jueves): una semana que empieza en un mes
    /// y termina en otro pertenece a aquel donde cae la mayoría de sus días. Es el mismo
    /// criterio que usaba el heatmap de la app antes de compartir esta función.
    static func segments(forWeekStarts weekStarts: [Date]) -> [HeatmapMonthSegment] {
        guard !weekStarts.isEmpty else { return [] }

        let calendar = AppCalendar.current
        var segments: [HeatmapMonthSegment] = []
        var currentKey: String?
        var currentLabel = ""
        var currentIndices: [Int] = []

        func flush() {
            guard let key = currentKey else { return }
            segments.append(
                HeatmapMonthSegment(id: key, label: currentLabel, weekIndices: currentIndices)
            )
        }

        for (weekIndex, weekStart) in weekStarts.enumerated() {
            let monthDate = calendar.date(byAdding: .day, value: 3, to: weekStart) ?? weekStart
            let components = calendar.dateComponents([.year, .month], from: monthDate)
            let key = "\(components.year ?? 0)-\(components.month ?? 0)"

            if key != currentKey {
                flush()
                currentKey = key
                currentLabel = AppFormatters.uppercasedString(from: monthDate, format: "MMM")
                currentIndices = []
            }

            currentIndices.append(weekIndex)
        }

        flush()
        return segments
    }
}
