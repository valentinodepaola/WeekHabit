//
//  FocusSessionActivityService.swift
//  WeekHabit
//
//  Lo que la Sesión de ritmo muestra fuera de la app: la Live Activity con la cuenta regresiva
//  y el aviso de fin. Las dos cosas nacen y mueren con la sesión, por eso van juntas.
//
//  Con el teléfono bloqueado la app no corre: la cuenta regresiva la dibuja el sistema a partir
//  de las fechas del `ContentState`, y el aviso de fin lo dispara el sistema a su hora. Con el
//  interruptor de silencio activado, ese aviso vibra pero no suena: sonar en silencio exigiría
//  AlarmKit o Critical Alerts, descartados en #22.
//
//  Si faltan los permisos, la sesión funciona igual: esto es un extra, no una condición.
//

import ActivityKit
import Foundation
import UserNotifications

enum FocusSessionActivityService {
    private static let endNoticePrefix = "focus-session-end"

    /// Cuánto puede quedar viva la actividad de una sesión libre, que no tiene hora de fin.
    /// Pasado ese tiempo el sistema la marca como vieja en vez de dejarla colgada.
    private static let openSessionStaleInterval: TimeInterval = 4 * 60 * 60

    static func start(session: FocusSession, isSequenced: Bool) async {
        // Una sola sesión a la vez: si quedó otra viva, se va antes de pedir la nueva.
        await endAll()

        let content = FocusSessionActivityAttributes.ContentState(session: session)
        requestActivity(
            attributes: FocusSessionActivityAttributes(session: session, isSequenced: isSequenced),
            content: content
        )

        if let endDate = content.endDate {
            await scheduleEndNotice(sessionID: session.id, at: endDate)
        }
    }

    /// Termina la actividad y cancela el aviso. Se llama al pasar a revisión, al cancelar y al
    /// guardar: en los tres casos el usuario ya está en la app y el aviso sobra.
    static func end(sessionID: UUID) async {
        for activity in Activity<FocusSessionActivityAttributes>.activities
        where activity.attributes.sessionID == sessionID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [endNoticeIdentifier(for: sessionID)])
    }

    /// Al arrancar la app ninguna vista tiene una sesión en memoria: si la app se cerró a la
    /// fuerza con una sesión en marcha, su actividad y su aviso quedaron huérfanos.
    static func endOrphans() async {
        await endAll()
    }

    private static func endAll() async {
        for activity in Activity<FocusSessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let identifiers = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("\(endNoticePrefix):") }
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func requestActivity(
        attributes: FocusSessionActivityAttributes,
        content: FocusSessionActivityAttributes.ContentState
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let staleDate = content.endDate ?? content.startDate.addingTimeInterval(openSessionStaleInterval)
        // Sin actividad la sesión sigue igual en la app, y no hay nada que el usuario pueda hacer
        // a mitad de una sesión: el error no se muestra.
        _ = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: content, staleDate: staleDate)
        )
    }

    private static func scheduleEndNotice(sessionID: UUID, at endDate: Date) async {
        let status = await HabitReminderService.authorizationStatus()
        guard status.allowsReminderScheduling else { return }

        let content = UNMutableNotificationContent()
        content.title = FocusSessionCopy.endNoticeTitle
        content.body = FocusSessionCopy.endNoticeBody
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let interval = endDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let request = UNNotificationRequest(
            identifier: endNoticeIdentifier(for: sessionID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func endNoticeIdentifier(for sessionID: UUID) -> String {
        "\(endNoticePrefix):\(sessionID.uuidString)"
    }
}
