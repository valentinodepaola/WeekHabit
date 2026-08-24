//
//  HelpCatalog.swift
//  WeekHabit
//
//  El copy de la pantalla de ayuda, fuera de la vista.
//
//  Vive aquí y no dentro de `TodayHelpSheet` por la misma razón que la leyenda de la semana vive
//  en `WeekGridCellFamily` y no en `WeekLegendSheet`: sin `import SwiftUI` esto es un value type
//  puro, se puede testear, y la vista queda reducida a pintar lo que el catálogo dice.
//
//  No es un catálogo de funciones: son las cinco formas de registrar el día que no se descubren
//  solas. Todo lo demás la app ya lo enseña donde ocurre.
//

import Foundation

/// El color de una fila. Se nombra por token semántico, no por color, para que la vista
/// resuelva `AppColor` y el catálogo siga sin depender de SwiftUI.
enum HelpTopicTint: Equatable {
    case accent
    case success
    case warning
    case info
}

/// Una fila de la ayuda: qué es y qué obtienes. Nunca cómo está implementado.
struct HelpTopic: Identifiable, Equatable {
    let id: String
    let icon: String
    let tint: HelpTopicTint
    let title: String
    let detail: String
}

enum HelpCatalog {

    static let title = "¿Qué puedo hacer?"

    static let subtitle = "Marcar completado no es la única opción. Estas son las otras formas de registrar tu día."

    static let topics: [HelpTopic] = [
        HelpTopic(
            id: "minimum",
            icon: "leaf.fill",
            tint: .success,
            title: "Hice la mínima",
            detail: "Si sólo alcanzó para la versión corta, cuenta igual y sostiene tu racha."
        ),
        HelpTopic(
            id: "rest",
            icon: "moon.stars",
            tint: .info,
            title: "Descanso intencional",
            detail: "Marca el día como descanso elegido. No rompe la racha ni se lee como fallo."
        ),
        HelpTopic(
            id: "wildcard",
            icon: "shield.fill",
            tint: .info,
            title: "Comodín",
            detail: "Una vez por semana, un día que faltó puede quedar cubierto para que la racha siga. Se aplica solo."
        ),
        HelpTopic(
            id: "slip",
            icon: "arrow.counterclockwise",
            tint: .warning,
            title: "Registrar un slip",
            detail: "En los hábitos que quieres dejar, anota la recaída y qué la detonó. Es información, no fracaso."
        ),
        HelpTopic(
            id: "urge",
            icon: "waveform.path.ecg",
            tint: .accent,
            title: "Tuve el impulso",
            detail: "Anota que aparecieron las ganas aunque no las hayas seguido. Con el tiempo verás a qué horas llegan."
        )
    ]
}
