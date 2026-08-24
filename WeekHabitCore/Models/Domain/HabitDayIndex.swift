//
//  HabitDayIndex.swift
//  WeekHabit
//

import Foundation

/// Agrupa las entradas y los comodines de un hábito por día, para que los recorridos que
/// consultan muchos días seguidos no vuelvan a escanear todo el historial en cada uno.
///
/// Las consultas equivalentes de `Habit` resuelven cada día con
/// `entries.contains { AppCalendar.isSameDay(...) }`, que es O(entradas). Un recorrido de
/// rachas hace eso hasta 1 825 veces, así que el costo es O(días × entradas). Este índice
/// lo baja a O(entradas) una sola vez más O(1) por consulta.
///
/// Construirlo **renormaliza** cada fecha con el calendario vigente. Eso es lo que lo hace
/// correcto si el usuario cruzó zonas horarias entre que escribió una entrada y la
/// consulta: comparar las fechas guardadas directamente fallaría en ese caso.
///
/// Es de un solo uso y barato: se construye al entrar a la función que lo necesita. Las
/// consultas de un solo día siguen usando la API de `Habit`, donde construirlo saldría más
/// caro que escanear.
struct HabitDayIndex {
    private let calendar: Calendar
    private let entriesByDay: [Date: [HabitEntry]]
    private let freezeDays: Set<Date>
    private let sessionTargetValue: Double

    init(_ habit: Habit) {
        // Se captura una sola vez y se reutiliza en todas las normalizaciones.
        let calendar = AppCalendar.current
        self.calendar = calendar
        self.sessionTargetValue = habit.sessionTargetValue

        var entriesByDay: [Date: [HabitEntry]] = [:]
        entriesByDay.reserveCapacity(habit.entries.count)
        for entry in habit.entries {
            entriesByDay[calendar.startOfDay(for: entry.date), default: []].append(entry)
        }
        self.entriesByDay = entriesByDay

        self.freezeDays = habit.allowsWeeklyFreeze
            ? Set(habit.streakFreezes.map { calendar.startOfDay(for: $0.protectedDate) })
            : []
    }

    // MARK: - Entradas del día

    func entries(on date: Date) -> [HabitEntry] {
        entriesByDay[calendar.startOfDay(for: date)] ?? []
    }

    func totalValue(on date: Date) -> Double {
        completedValue(on: date) { _ in true }
    }

    // MARK: - Estado del día

    func isCompleted(on date: Date) -> Bool {
        totalValue(on: date) >= sessionTargetValue
    }

    func isMinimumCompleted(on date: Date) -> Bool {
        contains(.minimum, on: date)
    }

    func isSkipped(on date: Date) -> Bool {
        contains(.skipped, on: date)
    }

    func isMissed(on date: Date) -> Bool {
        contains(.missed, on: date)
    }

    func isSlip(on date: Date) -> Bool {
        contains(.slip, on: date)
    }

    func hasUrge(on date: Date) -> Bool {
        contains(.urge, on: date)
    }

    func hasAnyEntry(on date: Date) -> Bool {
        entries(on: date).contains { $0.kind != .urge }
    }

    // MARK: - Comodines

    func isFreezeProtected(on date: Date) -> Bool {
        freezeDays.contains(calendar.startOfDay(for: date))
    }

    func preservesStreakWithoutCompletion(on date: Date) -> Bool {
        isSkipped(on: date) || isFreezeProtected(on: date)
    }

    // MARK: - Insights

    /// Solo cuenta marcas confiables: las manuales sirven de historial pero no son
    /// evidencia de ritmo.
    func isTrustedCompleted(on date: Date) -> Bool {
        completedValue(on: date) { $0.source.isTrustedForInsights } >= sessionTargetValue
    }

    func hasTrustedMinimum(on date: Date) -> Bool {
        entries(on: date).contains {
            $0.kind == .minimum && $0.source.isTrustedForInsights
        }
    }

    /// El día se completó solo con marcas retroactivas: sirve de historial pero no cuenta
    /// como evidencia de ritmo.
    func isManualCompleted(on date: Date) -> Bool {
        completedValue(on: date) { $0.source == .manual } >= sessionTargetValue
    }

    /// Los días con al menos una entrada, ya normalizados. Evita recorrer las entradas
    /// crudas cuando solo interesan las fechas.
    var recordedDays: some Collection<Date> {
        entriesByDay.keys
    }

    // MARK: - Helpers

    private func contains(_ kind: EntryKind, on date: Date) -> Bool {
        entries(on: date).contains { $0.kind == kind }
    }

    private func completedValue(
        on date: Date,
        where isIncluded: (HabitEntry) -> Bool
    ) -> Double {
        entries(on: date)
            .filter { $0.kind == .completed && isIncluded($0) }
            .reduce(0) { partial, entry in
                partial + (entry.value ?? Double(entry.completedCount))
            }
    }
}
