//
//  HabitCollection+DailyNotice.swift
//  WeekHabit
//

import Foundation

/// Un aviso diario ya resuelto: cuándo suena y qué dice.
///
/// Es de dominio puro para que la regla de "cuándo callarse" se pueda probar sin
/// `UNUserNotificationCenter`. El servicio solo traduce estas ocurrencias a requests.
struct DailyNoticeOccurrence: Equatable {
    /// Inicio del día al que pertenece el aviso. Es la llave del request.
    let day: Date
    let fireDate: Date
    let title: String
    let body: String
}

/// Reglas y copy del aviso diario.
enum DailyNotice {
    /// Cuántos días hacia adelante se agendan avisos sueltos.
    ///
    /// Una notificación repetida no se puede saltar un día, y el aviso tiene que callarse
    /// cuando el día ya está cerrado. Por eso se agenda una por día y se recalculan todas
    /// cada vez que la app entra o sale de primer plano.
    static let windowDays = 7

    /// Cuántos nombres de hábito entran en el cuerpo antes de resumir con "y N más".
    static let listedHabits = 2

    /// Completados confiables que necesita la franja pico para sostener una sugerencia.
    ///
    /// Con menos, `peakHour()` devuelve la hora de un par de registros sueltos, y eso no es
    /// un patrón que valga la pena sugerir.
    static let suggestionMinimumCount = 5

    /// Hora fija con la que arranca el selector. Nunca se deriva de los datos.
    static let defaultHour = 20
    static let defaultMinute = 0

    static func title(pendingCount: Int) -> String {
        pendingCount == 1
            ? "Te queda 1 hábito hoy"
            : "Te quedan \(pendingCount) hábitos hoy"
    }

    /// La sugerencia se lee como una observación, no como una decisión ya tomada.
    static func suggestionText(for window: HourWindow) -> String {
        "Los últimos 30 días sueles completar tus hábitos entre \(hourPhrase(window.startHour)) y \(hourPhrase(window.endHour))."
    }

    static func suggestionActionTitle(for window: HourWindow) -> String {
        "Usar \(hourPhrase(window.startHour))"
    }

    /// "las 21:00", pero "la 1:00": en español la una va en singular.
    private static func hourPhrase(_ hour: Int) -> String {
        let article = hour == 1 ? "la" : "las"
        return String(format: "%@ %d:00", article, hour)
    }

    /// "Leer", "Leer y Caminar", "Leer, Caminar y 3 más".
    static func body(pendingTitles: [String]) -> String {
        let listed = Array(pendingTitles.prefix(listedHabits))
        let hidden = pendingTitles.count - listed.count

        if hidden > 0 {
            return listed.joined(separator: ", ") + " y \(hidden) más"
        }

        switch listed.count {
        case 0: return ""
        case 1: return listed[0]
        default: return listed.dropLast().joined(separator: ", ") + " y " + listed[listed.count - 1]
        }
    }
}

extension Array where Element == Habit {
    /// Los avisos de los próximos `days` días, empezando por el de `reference`.
    ///
    /// Un día queda fuera si no le queda nada pendiente —todo hecho, descanso, pausa o nada
    /// programado— o si es hoy y la hora ya pasó.
    ///
    /// El conteo de un día futuro es exacto mientras el usuario no abra la app: registrar
    /// solo se puede desde la app —los widgets son de solo lectura—, y abrirla vuelve a
    /// calcular todo.
    func dailyNoticeOccurrences(
        hour: Int,
        minute: Int,
        days: Int = DailyNotice.windowDays,
        reference: Date = .now
    ) -> [DailyNoticeOccurrence] {
        let calendar = AppCalendar.current
        let firstDay = AppCalendar.startOfDay(for: reference)
        let clampedHour = Swift.min(Swift.max(hour, 0), 23)
        let clampedMinute = Swift.min(Swift.max(minute, 0), 59)

        return (0..<Swift.max(days, 0)).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay),
                  let fireDate = calendar.date(
                    bySettingHour: clampedHour,
                    minute: clampedMinute,
                    second: 0,
                    of: day
                  ),
                  fireDate > reference else {
                return nil
            }

            let pending = loggableToday(on: day).todayPartition(on: day).pending
            guard !pending.isEmpty else { return nil }

            return DailyNoticeOccurrence(
                day: day,
                fireDate: fireDate,
                title: DailyNotice.title(pendingCount: pending.count),
                body: DailyNotice.body(pendingTitles: pending.map(\.title))
            )
        }
    }
}

extension Sequence where Element == Habit {
    /// La franja en que el usuario suele completar sus hábitos, si hay datos que la sostengan.
    ///
    /// Solo se ofrece como dato junto al selector de hora: nunca decide la hora del aviso.
    /// Cuenta solo hábitos a construir, igual que "Tu hora punta" en Insights: el completado
    /// de un hábito a dejar no dice a qué hora el usuario suele hacer sus cosas.
    func dailyNoticeSuggestedWindow(reference: Date = .now) -> HourWindow? {
        let buildHabits = filter { !$0.isBreakHabit }
        guard buildHabits.insightReadiness(reference: reference).isReady,
              let window = buildHabits.peakHour(reference: reference),
              window.count >= DailyNotice.suggestionMinimumCount else {
            return nil
        }
        return window
    }
}
