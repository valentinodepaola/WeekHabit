//
//  FocusSessionActivityAttributes.swift
//  WeekHabit
//
//  El contrato de la Live Activity de la Sesión de ritmo. Vive en `WeekHabitCore` porque lo
//  necesitan los dos lados: la app la pide y la termina, la extensión la dibuja.
//

import ActivityKit
import Foundation

/// `nonisolated` porque el sistema lo codifica fuera del hilo principal; con el aislamiento por
/// defecto del módulo (`MainActor`) la conformidad a `ActivityAttributes` quedaría aislada.
nonisolated struct FocusSessionActivityAttributes: ActivityAttributes {
    /// Lo que la actividad dibuja y podría cambiar. Hoy no cambia nunca: la app no puede
    /// actualizarla con el teléfono bloqueado, así que la cuenta regresiva la dibuja el sistema
    /// a partir de estas dos fechas.
    struct ContentState: Codable, Hashable {
        let startDate: Date
        /// `nil` en una sesión libre: la actividad cuenta hacia arriba y no hay fin que anunciar.
        let endDate: Date?
    }

    let sessionID: UUID
    let habitCount: Int
    let isSequenced: Bool
}

extension FocusSessionActivityAttributes {
    @MainActor
    init(session: FocusSession, isSequenced: Bool) {
        self.init(
            sessionID: session.id,
            habitCount: session.selectedHabitIDs.count,
            isSequenced: isSequenced
        )
    }

    var subtitle: String {
        FocusSessionCopy.focusSubtitle(habitCount: habitCount, isSequenced: isSequenced)
    }
}

extension FocusSessionActivityAttributes.ContentState {
    @MainActor
    init(session: FocusSession) {
        self.init(startDate: session.startedAt, endDate: session.scheduledEndDate)
    }
}

/// Copy de la Sesión de ritmo que comparten la pantalla de la sesión y su Live Activity, para
/// que las dos nombren igual lo que está en enfoque.
nonisolated enum FocusSessionCopy {
    static let activityTitle = "Sesión de ritmo"
    static let endNoticeTitle = "Terminó tu sesión de ritmo"
    static let endNoticeBody = "Cuéntanos qué lograste."
    /// Lo que muestra la actividad cuando llegó su hora y la app todavía no la cerró.
    static let finishedLabel = "Terminó"
    static let finishedDetail = "Abre la app para cerrarla"

    static func focusSubtitle(habitCount: Int, isSequenced: Bool) -> String {
        if isSequenced && habitCount > 1 {
            return "\(habitCount) hábitos en secuencia"
        }
        return habitCount == 1 ? "1 hábito en enfoque" : "\(habitCount) hábitos en enfoque"
    }
}
