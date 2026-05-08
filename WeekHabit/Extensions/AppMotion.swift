//
//  AppMotion.swift
//  WeekHabit
//
//  Curvas de animación unificadas. Cada componente referencia un token; no se
//  inventan curvas locales. Reduce Motion respetado vía `reduceMotionAware`.
//

import SwiftUI

enum AppMotion {

    /// Micro-toggles, swipes cortos. Spring rápido, ligeramente firme.
    static let snap = Animation.spring(response: 0.28, dampingFraction: 0.85)
    /// Default para transiciones de estado.
    static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.85)
    /// Sheets, transiciones de página, expansiones grandes.
    static let gentle = Animation.spring(response: 0.65, dampingFraction: 0.9)
    /// Cierres de hábito, microcelebraciones. Rebote leve.
    static let celebration = Animation.spring(response: 0.5, dampingFraction: 0.6)
    /// Fades cortos.
    static let linearOut = Animation.easeOut(duration: 0.18)

    /// Devuelve `nil` cuando Reduce Motion está activo, lo que en SwiftUI
    /// equivale a aplicar el cambio sin animación. Uso:
    ///
    ///     withAnimation(AppMotion.respectful(.smooth, reduceMotion)) { ... }
    static func respectful(_ animation: Animation, _ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
