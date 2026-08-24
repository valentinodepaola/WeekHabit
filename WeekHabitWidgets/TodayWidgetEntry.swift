//
//  TodayWidgetEntry.swift
//  WeekHabitWidgets
//

import Foundation
import WidgetKit

/// Una entrada de la línea de tiempo del widget.
///
/// El contenido es un enum y no un snapshot opcional porque las dos ramas se dibujan
/// distinto y ninguna puede caer en la otra por descuido: un fallo de lectura mostrado como
/// snapshot vacío se vería como un día perfecto, que es justo la mentira que hay que evitar.
struct TodayWidgetEntry: TimelineEntry {
    enum Content: Equatable {
        case snapshot(TodayWidgetSnapshot)
        /// No se pudo leer la base compartida.
        case unavailable
    }

    let date: Date
    let content: Content

    static func placeholder(date: Date = .now) -> TodayWidgetEntry {
        TodayWidgetEntry(date: date, content: .snapshot(.placeholder))
    }
}
