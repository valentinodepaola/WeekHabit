//
//  DailyNoticeService.swift
//  WeekHabit
//
//  Aviso diario "te quedan N hábitos hoy". Es el único aviso de la app que llega con un
//  Focus activo (`.timeSensitive`); el recordatorio por hábito conserva el nivel normal para
//  que la app no gaste ese permiso en varias interrupciones al día.
//
//  Se agenda como avisos sueltos para los próximos días, no como uno repetido: uno repetido
//  no se puede saltar un día ya cerrado. Las ocurrencias las decide
//  `dailyNoticeOccurrences(hour:minute:days:reference:)`; acá solo se traducen a requests.
//

import Foundation
import UserNotifications

enum DailyNoticeService {
    /// Llaves de `@AppStorage`. Viven acá para que la pantalla de avisos y `RootView` lean
    /// las mismas preferencias sin repetir el string.
    static let isEnabledKey = "dailyNoticeEnabled"
    static let hourKey = "dailyNoticeHour"
    static let minuteKey = "dailyNoticeMinute"

    private static let identifierPrefix = "daily-notice"

    /// Borra los avisos agendados y vuelve a agendar los que correspondan.
    ///
    /// Lanza el primer error del centro de notificaciones para que la pantalla de avisos lo
    /// muestre. El refresco de fondo puede ignorarlo, como los demás recordatorios.
    static func refresh(habits: [Habit], isEnabled: Bool, hour: Int, minute: Int) async throws {
        await cancelAll()

        guard isEnabled else { return }
        let status = await HabitReminderService.authorizationStatus()
        guard status.allowsReminderScheduling else { return }

        for occurrence in habits.dailyNoticeOccurrences(hour: hour, minute: minute) {
            try await add(request(for: occurrence))
        }
    }

    static func cancelAll() async {
        let identifiers = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("\(identifierPrefix):") }

        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Si el usuario apagó "Notificaciones urgentes" para la app en Ajustes. El aviso sigue
    /// llegando, pero ya no atraviesa un Focus; la pantalla de avisos lo dice.
    static func isTimeSensitiveDisabled() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().timeSensitiveSetting == .disabled
    }

    private static func request(for occurrence: DailyNoticeOccurrence) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = occurrence.title
        content.body = occurrence.body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var components = AppCalendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: occurrence.fireDate
        )
        components.calendar = AppCalendar.current
        components.timeZone = .current

        return UNNotificationRequest(
            identifier: identifier(for: occurrence.day),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    /// `daily-notice:2026-09-23`: una llave por día, legible al depurar los pendientes.
    private static func identifier(for day: Date) -> String {
        let components = AppCalendar.current.dateComponents([.year, .month, .day], from: day)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let dayOfMonth = components.day ?? 0
        return String(format: "%@:%04d-%02d-%02d", identifierPrefix, year, month, dayOfMonth)
    }

    private static func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
}
