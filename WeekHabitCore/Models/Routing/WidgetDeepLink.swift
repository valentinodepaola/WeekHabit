//
//  WidgetDeepLink.swift
//  WeekHabit
//

import Foundation

/// El enlace que abre el widget.
///
/// Vive en el código compartido y no en cada target por la misma razón que `AppGroupStore`:
/// si el widget escribiera una URL y la app esperara otra, tocar el widget abriría la app en
/// la pestaña equivocada y nada fallaría de forma visible.
enum WidgetDeepLink {
    static let scheme = "weekhabit"

    /// Lleva a la pestaña Hoy, que es donde el usuario puede actuar sobre lo que acaba de
    /// leer en el widget.
    static let today = URL(string: "\(scheme)://today")

    /// Lleva a Insights, que es donde el ritmo a largo plazo se explica. El widget "Año de
    /// constancia" habla de eso, no de lo que falta hoy.
    static let insights = URL(string: "\(scheme)://insights")

    /// True si la URL recibida es la del widget de hoy.
    static func isToday(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == "today"
    }

    /// True si la URL recibida es la del widget del año.
    static func isInsights(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == "insights"
    }
}
