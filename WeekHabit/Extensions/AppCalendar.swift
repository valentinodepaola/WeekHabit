//
//  AppCalendar.swift
//  WeekHabit
//
//  Single source of truth for date math. Always use this instead of `Calendar.current`
//  directly so that timezone/locale assumptions stay consistent across the app.
//

import Foundation
import os

enum AppCalendar {
    /// Locale-aware calendar with the user's current timezone.
    /// Force Monday as first weekday — the app's week is L–D regardless of locale.
    ///
    /// El valor se cachea a propósito. Construir un `Calendar` obliga a resolver
    /// `TimeZone.current` y `Locale.current`, que son búsquedas del sistema, y el dominio
    /// pasa por acá cientos de miles de veces al recorrer rachas o historial. El caché se
    /// descarta cuando iOS avisa que cambió la zona horaria o el idioma, así que los
    /// límites de día siguen siendo correctos si el usuario viaja con la app abierta.
    static var current: Calendar {
        _ = invalidationObserver

        // Cinturón además de los tirantes: la notificación puede no llegar, pero un
        // calendario con la zona horaria vieja siempre se detecta acá. Solo se compara la
        // zona horaria porque es de lo único que dependen los límites de día; el
        // `firstWeekday` está forzado y el idioma lo cubre la notificación.
        let systemTimeZone = TimeZone.current

        return cachedCalendar.withLock { cached in
            if let cached, cached.timeZone == systemTimeZone { return cached }

            let calendar = makeCalendar()
            cached = calendar
            return calendar
        }
    }

    /// Descarta el calendario cacheado.
    ///
    /// La usa el observador de notificaciones. Es `internal` en vez de `private` para que
    /// el caché tenga una costura verificable desde las pruebas.
    static func invalidateCache() {
        cachedCalendar.withLock { $0 = nil }
    }

    /// Strip the time component, returning the start of the given day.
    static func startOfDay(for date: Date) -> Date {
        current.startOfDay(for: date)
    }

    /// `Weekday` for the given date.
    static func weekday(of date: Date) -> Weekday {
        let raw = current.component(.weekday, from: date)
        return Weekday(rawValue: raw) ?? .monday
    }

    /// Half-open range `[start, end)` covering the calendar week containing `date`.
    static func weekRange(containing date: Date) -> Range<Date> {
        let cal = current
        let start = cal.dateInterval(of: .weekOfYear, for: date)?.start
            ?? cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
        return start..<end
    }

    /// True iff the two dates fall on the same calendar day.
    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        current.isDate(a, inSameDayAs: b)
    }

    // MARK: - Caché

    /// `AppCalendar` se usa desde cualquier contexto y no está aislado a ningún actor, así
    /// que el caché necesita su propio lock.
    private static let cachedCalendar = OSAllocatedUnfairLock<Calendar?>(initialState: nil)

    /// Se toca desde `current` para suscribirse una sola vez: los `static let` de Swift son
    /// lazy y thread-safe, así que alcanza con referenciarlo.
    private static let invalidationObserver: Void = {
        let notificationNames: [Notification.Name] = [
            NSLocale.currentLocaleDidChangeNotification,
            .NSSystemTimeZoneDidChange
        ]

        for name in notificationNames {
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: nil
            ) { _ in
                invalidateCache()
            }
        }
    }()

    private static func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale = .current
        calendar.firstWeekday = Weekday.monday.rawValue
        return calendar
    }
}
