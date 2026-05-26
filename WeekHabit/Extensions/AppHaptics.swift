//
//  AppHaptics.swift
//  WeekHabit
//
//  Wrapper centralizado para feedback háptico. El criterio del producto es
//  que los haptics se reservan para cierres con peso emocional (completar
//  hábito, cerrar el día, cerrar foco) y nunca para navegación.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppHaptics {

    enum Event {
        /// Marcar un hábito como completado.
        case habitCompleted
        /// Resistir un impulso en un hábito break.
        case urgeAvoided
        /// Registrar que hubo impulso sin convertirlo en slip.
        case urgeLogged
        /// Registrar un slip sin tono punitivo.
        case slipLogged
        /// Registrar una cantidad parcial.
        case quantityLogged
        /// Registrar una cantidad que cruza la meta.
        case quantityCompleted
        /// Marcar o quitar descanso.
        case skipToggled
        /// Último hábito del día completado.
        case dayClosed
        /// Cierre de sesión de foco.
        case focusClosed
        /// Mantener / aplicar experimento.
        case experimentApplied
        /// Acción destructiva revelada (swipe).
        case warning
        /// Cambio de selección puntual.
        case selection
    }

    static func play(_ event: Event) {
        #if canImport(UIKit)
        switch event {
        case .habitCompleted, .quantityCompleted, .dayClosed, .focusClosed, .experimentApplied:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .urgeAvoided:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                let success = UINotificationFeedbackGenerator()
                success.notificationOccurred(.success)
            }
        case .urgeLogged:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        case .slipLogged:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .quantityLogged, .skipToggled, .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        #endif
    }
}
