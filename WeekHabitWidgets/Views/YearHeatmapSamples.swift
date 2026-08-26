//
//  YearHeatmapSamples.swift
//  WeekHabitWidgets
//

#if DEBUG
import Foundation

/// Datos de muestra para las previews del widget del año.
///
/// Se arman como hábitos sintéticos y se pasan por el `init` real de `YearHeatmapSnapshot`, en
/// vez de escribir 52 semanas de celdas a mano: así la preview ejercita la misma derivación
/// que el widget en producción.
extension YearHeatmapSnapshot {

    /// Año consistente: tres hábitos diarios cumplidos casi siempre.
    static var sampleStrongYear: YearHeatmapSnapshot {
        YearHeatmapSnapshot(habits: sampleHabits(missEvery: 9), referenceDate: .now)
    }

    /// Año irregular: se cumple algo más o menos la mitad de los días.
    static var sampleMixedYear: YearHeatmapSnapshot {
        YearHeatmapSnapshot(habits: sampleHabits(missEvery: 2), referenceDate: .now)
    }

    /// Recién empezado: los hábitos existen hace diez días, el resto de la grilla es fuera de
    /// rango.
    static var sampleEarlyDays: YearHeatmapSnapshot {
        YearHeatmapSnapshot(habits: sampleHabits(missEvery: 3, ageInDays: 10), referenceDate: .now)
    }

    /// Sin hábitos todavía.
    static var sampleEmpty: YearHeatmapSnapshot {
        YearHeatmapSnapshot(habits: [], referenceDate: .now)
    }

    // MARK: - Fábrica

    private static func sampleHabits(missEvery: Int, ageInDays: Int = 372) -> [Habit] {
        let calendar = AppCalendar.current
        let today = AppCalendar.startOfDay(for: .now)
        let createdAt = calendar.date(byAdding: .day, value: -ageInDays, to: today) ?? today
        let span = min(ageInDays, 366)

        return (0..<3).map { habitIndex in
            let habit = Habit(
                title: ["Leer", "Correr", "Meditar"][habitIndex],
                colorHex: ["#5c89a8", "#5e8c61", "#8b7fb0"][habitIndex],
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered),
                scheduleKind: .daily,
                createdAt: createdAt
            )

            habit.entries = (0...span).compactMap { dayOffset in
                // Un desfase por hábito para que muchos días queden a medias, no todo-o-nada.
                guard (dayOffset + habitIndex) % missEvery != 0,
                      let date = calendar.date(byAdding: .day, value: dayOffset, to: createdAt),
                      date <= today else {
                    return nil
                }
                return HabitEntry(date: date, source: .today, kind: .completed, habit: habit)
            }

            return habit
        }
    }
}
#endif
