//
//  YearHeatmapSnapshot.swift
//  WeekHabit
//

import Foundation

/// Cómo se ve un día en la grilla agregada del widget "Año de constancia".
///
/// Son cuatro casos y no una sola intensidad porque "programado y no hice nada" y "no había
/// nada programado" son hechos distintos, y pintarlos igual convierte una semana de descanso
/// —o los días previos al primer hábito— en una racha de fallas.
enum YearHeatmapDayKind: Equatable, Hashable {
    /// Se cumplió algo ese día. `level` va de 1 a 3 según la fracción cumplida.
    case done(level: Int)
    /// Había hábitos programados y no se completó ninguno.
    case scheduledNothingDone
    /// Nada programado ese día, o todo lo programado quedó neutralizado por descanso o comodín.
    case nothingScheduled
    /// Antes del primer hábito o en el futuro: no hay nada que evaluar.
    case outOfRange
}

/// Un día de la grilla: los conteos crudos y el caso ya resuelto.
struct YearHeatmapDay: Equatable {
    /// Inicio del día, ya normalizado.
    let date: Date
    /// Hábitos de día fijo, loggables y no neutralizados (descanso/comodín) ese día.
    let scheduledCount: Int
    /// De esos, cuántos alcanzaron su meta del día.
    let completedCount: Int
    /// `completedCount / scheduledCount`; 0 cuando no había programados.
    let intensity: Double
    let kind: YearHeatmapDayKind
}

/// Una semana de la grilla: 7 días ordenados L→D.
struct YearHeatmapWeek: Equatable, Identifiable {
    /// Índice de semana. 0 es la más vieja de la ventana.
    let id: Int
    /// Inicio (lunes) de la semana.
    let start: Date
    let days: [YearHeatmapDay]
}

/// Todo lo que el widget del año dibuja, derivado **una sola vez** a partir de los hábitos.
///
/// Mismo patrón y misma razón que `TodayWidgetSnapshot`: la derivación no puede vivir en la
/// vista porque la vista está en la extensión, donde el target de pruebas no llega. En un
/// value type del módulo de modelos, `WeekHabitTests` sí la alcanza.
struct YearHeatmapSnapshot: Equatable {

    /// 52 semanas —un año— es la ventana de la única familia soportada (`systemLarge`).
    static let defaultWeeks = 52

    /// Semanas de la ventana, de la más vieja a la de `referenceDate`.
    let weeks: [YearHeatmapWeek]
    let hasAnyHabit: Bool
    /// Días dentro de rango con al menos un hábito programado.
    let trackedDays: Int
    /// De `trackedDays`, cuántos cerraron al 100%.
    let perfectDays: Int
    /// Promedio de `intensity` sobre `trackedDays`. Es la métrica del encabezado.
    let completionRate: Double

    // MARK: - Derivación

    init(
        habits: [Habit],
        referenceDate: Date = .now,
        weeks weekCount: Int = YearHeatmapSnapshot.defaultWeeks
    ) {
        guard weekCount > 0 else {
            self.init(
                weeks: [],
                hasAnyHabit: !habits.isEmpty,
                trackedDays: 0,
                perfectDays: 0,
                completionRate: 0
            )
            return
        }

        // Capturado una vez fuera de los bucles: cada acceso a `AppCalendar.current` toca un
        // lock y resuelve la zona horaria del sistema.
        let calendar = AppCalendar.current
        let referenceDay = AppCalendar.startOfDay(for: referenceDate)
        let currentWeekStart = AppCalendar.weekRange(containing: referenceDay).lowerBound

        // Solo hábitos con día fijo. Un flexible da `isLoggable == true` los 7 días y
        // `meetsTodaySectionTarget == true` toda la semana una vez cumplida la meta: incluirlo
        // pintaría siete días al 100% por un solo registro, que no es lo que la grilla afirma.
        let fixedHabits = habits.filter { !$0.isFlexibleSchedule }

        // Un `HabitDayIndex` por hábito, construido antes del recorrido de días y reutilizado
        // en los ~364. Es el patrón de `todayPartition(on:)` y la razón que documenta la
        // cabecera de `HabitDayIndex`.
        let indexed = fixedHabits.map { (habit: $0, index: HabitDayIndex($0)) }

        // El rango arranca en el primer hábito creado —cualquiera, no solo los de día fijo—:
        // antes de esa fecha no había nada que la app pudiera registrar.
        let firstCreationDay = habits
            .map { AppCalendar.startOfDay(for: $0.createdAt) }
            .min()

        var builtWeeks: [YearHeatmapWeek] = []
        builtWeeks.reserveCapacity(weekCount)
        var trackedDays = 0
        var perfectDays = 0
        var intensitySum = 0.0

        for weekIndex in 0..<weekCount {
            let offset = weekIndex - (weekCount - 1)
            let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)
                ?? currentWeekStart

            var days: [YearHeatmapDay] = []
            days.reserveCapacity(7)

            for dayOffset in 0..<7 {
                let rawDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
                let day = AppCalendar.startOfDay(for: rawDate)

                // `isPaused` no es retroactivo (exige `día >= hoy`), así que un día pasado
                // nunca reporta pausa; como la ventana termina en `referenceDay`, la asimetría
                // no afecta a esta grilla. No "arreglar" pidiéndole pausa a días viejos.
                let outOfRange = day > referenceDay || (firstCreationDay.map { day < $0 } ?? true)

                guard !outOfRange else {
                    days.append(
                        YearHeatmapDay(
                            date: day,
                            scheduledCount: 0,
                            completedCount: 0,
                            intensity: 0,
                            kind: .outOfRange
                        )
                    )
                    continue
                }

                var scheduled = 0
                var completed = 0

                for entry in indexed {
                    guard entry.habit.isLoggable(on: day) else { continue }

                    // El comodín y el descanso existen para que un día no cuente. Ese hábito
                    // sale del numerador y del denominador, igual que `activeCount` en
                    // `TodayPartition` descuenta los descansos.
                    if entry.index.isFreezeProtected(on: day) || entry.index.isSkipped(on: day) {
                        continue
                    }

                    scheduled += 1
                    if entry.habit.meetsTodaySectionTarget(on: day, index: entry.index) {
                        completed += 1
                    }
                }

                let intensity = scheduled > 0 ? Double(completed) / Double(scheduled) : 0

                if scheduled > 0 {
                    trackedDays += 1
                    intensitySum += intensity
                    if completed == scheduled { perfectDays += 1 }
                }

                days.append(
                    YearHeatmapDay(
                        date: day,
                        scheduledCount: scheduled,
                        completedCount: completed,
                        intensity: intensity,
                        kind: Self.kind(scheduled: scheduled, intensity: intensity)
                    )
                )
            }

            builtWeeks.append(YearHeatmapWeek(id: weekIndex, start: weekStart, days: days))
        }

        self.init(
            weeks: builtWeeks,
            hasAnyHabit: !habits.isEmpty,
            trackedDays: trackedDays,
            perfectDays: perfectDays,
            completionRate: trackedDays > 0 ? intensitySum / Double(trackedDays) : 0
        )
    }

    /// Construcción directa, sin pasar por los hábitos. La usan el marcador de posición del
    /// widget y sus previews.
    init(
        weeks: [YearHeatmapWeek],
        hasAnyHabit: Bool,
        trackedDays: Int,
        perfectDays: Int,
        completionRate: Double
    ) {
        self.weeks = weeks
        self.hasAnyHabit = hasAnyHabit
        self.trackedDays = trackedDays
        self.perfectDays = perfectDays
        self.completionRate = completionRate
    }

    /// Grilla vacía para el marcador de posición del widget, antes de que haya datos.
    static let placeholder = YearHeatmapSnapshot(habits: [], referenceDate: .now)

    // MARK: - Privados

    /// Cero más tres niveles discretos de `.done`, y no una opacidad continua: a ~6 pt de
    /// celda, dos días con 60% y 70% se ven iguales; los pasos discretos se distinguen. Nunca
    /// nivel 0 para `intensity > 0` —cualquier avance real tiene que verse—.
    private static func kind(scheduled: Int, intensity: Double) -> YearHeatmapDayKind {
        guard scheduled > 0 else { return .nothingScheduled }
        guard intensity > 0 else { return .scheduledNothingDone }
        if intensity <= 1.0 / 3 { return .done(level: 1) }
        if intensity <= 2.0 / 3 { return .done(level: 2) }
        return .done(level: 3)
    }
}
