//
//  YearHeatmapAppearance.swift
//  WeekHabitWidgets
//

import SwiftUI

/// Cómo se pinta cada celda de la grilla del año.
///
/// Vive aparte del snapshot —que es dominio puro y no conoce `Color`— y aparte de la vista,
/// para que los tres pasos de opacidad se calibren en un solo lugar contra el simulador en
/// claro y oscuro.
enum YearHeatmapAppearance {

    /// Relleno de la celda. Tres pasos de `AppColor.accent` para los días con algo cumplido;
    /// `bgSunken` para el resto. El paso más bajo ya tiene que verse: es el piso de
    /// "algo pasó ese día".
    static func fill(for kind: YearHeatmapDayKind) -> Color {
        switch kind {
        case .done(let level):
            switch level {
            case 1: return AppColor.accent.opacity(0.28)
            case 2: return AppColor.accent.opacity(0.62)
            default: return AppColor.accent
            }
        case .scheduledNothingDone, .nothingScheduled:
            return AppColor.bgSunken
        case .outOfRange:
            return AppColor.bgSunken.opacity(0.4)
        }
    }

    /// Un borde tenue —y solo él— separa "programado y no hice nada" de "no había nada": a
    /// tamaño de celda, un contorno se lee antes que un segundo tono de gris casi igual.
    static func border(for kind: YearHeatmapDayKind) -> Color {
        kind == .scheduledNothingDone ? AppColor.divider : .clear
    }
}
