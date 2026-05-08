//
//  AppRadius.swift
//  WeekHabit
//
//  Escala de border-radius. Toda esquina redondeada referencia un token.
//

import Foundation
import CoreGraphics

enum AppRadius {

    // MARK: - New scale

    /// 6pt — chips internos pequeños.
    static let xs: CGFloat = 6
    /// 10pt — badges, toggles de día, chips.
    static let s: CGFloat = 10
    /// 14pt — inputs, cards pequeñas.
    static let m: CGFloat = 14
    /// 20pt — cards principales.
    static let l: CGFloat = 20
    /// 28pt — sheets, hero containers.
    static let xl: CGFloat = 28
    /// Capsule shape.
    static let capsule: CGFloat = 999

    // MARK: - Legacy aliases
    // Compatibility shims. No agregar nuevos usos — deuda técnica a migrar.

    static let small: CGFloat = s
    static let medium: CGFloat = m
    /// Antes 14, ahora alineado a `m`.
    static let large: CGFloat = m
    /// Legacy: 15pt. La pill real ahora vive en `capsule`.
    static let pill: CGFloat = 15
}
