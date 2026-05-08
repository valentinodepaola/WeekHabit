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
        case .habitCompleted, .dayClosed, .focusClosed, .experimentApplied:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        #endif
    }
}
