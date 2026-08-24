//
//  TodayWidgetAppearance.swift
//  WeekHabitWidgets
//

import SwiftUI

/// Cómo se ve cada estado: su color semántico y su símbolo.
///
/// Vive aparte de las vistas porque las cuatro familias tienen que coincidir. Si cada una
/// eligiera su propio color, el mismo día se vería salvia en la pantalla de inicio y
/// terracota en la de bloqueo.
///
/// Los colores salen de los tokens semánticos y no de una paleta propia: pendiente en acento,
/// cerrado en salvia, descanso en violeta. Ninguno es rojo — un día sin cerrar es un dato,
/// no una falla.
extension TodayWidgetState {

    var tint: Color {
        switch self {
        case .pending: return AppColor.accent
        case .allDone: return AppColor.success
        case .rest: return AppColor.info
        case .empty: return AppColor.accent
        }
    }

    /// Fondo suave del glifo, para los estados que no dibujan anillo.
    var mutedTint: Color {
        switch self {
        case .rest: return AppColor.infoMuted
        default: return AppColor.accentMuted
        }
    }

    /// Símbolo del centro. `nil` en el estado con pendientes, que muestra la cifra.
    var symbolName: String? {
        switch self {
        case .pending: return nil
        case .allDone: return "checkmark"
        case .rest: return "leaf.fill"
        case .empty: return "plus"
        }
    }

    /// Si el estado se representa con el anillo de progreso o con un glifo suelto.
    ///
    /// Descanso y "sin hábitos" no llevan anillo a propósito: un anillo vacío se lee como un
    /// cero, y un cero se lee como una falla. Sin nada que medir, no se dibuja una medida.
    var showsProgressRing: Bool {
        switch self {
        case .pending, .allDone: return true
        case .rest, .empty: return false
        }
    }
}
