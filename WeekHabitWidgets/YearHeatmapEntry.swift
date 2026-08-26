//
//  YearHeatmapEntry.swift
//  WeekHabitWidgets
//

import Foundation
import WidgetKit

/// Una entrada de la línea de tiempo del widget "Año de constancia".
///
/// El contenido es un enum y no un snapshot opcional por la misma razón que en el widget de
/// hoy: un fallo de lectura dibujado como grilla vacía se leería como un año impecable, que es
/// justo la mentira que hay que evitar.
struct YearHeatmapEntry: TimelineEntry {
    enum Content: Equatable {
        case snapshot(YearHeatmapSnapshot)
        /// No se pudo leer la base compartida.
        case unavailable
    }

    let date: Date
    let content: Content

    static func placeholder(date: Date = .now) -> YearHeatmapEntry {
        YearHeatmapEntry(date: date, content: .snapshot(.placeholder))
    }
}
