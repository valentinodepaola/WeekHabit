//
//  PerformanceSeedService.swift
//  WeekHabit
//

#if DEBUG
import Foundation
import SwiftData

struct PerformanceSeedResult {
    let insertedHabitCount: Int
    let insertedEntryCount: Int
    let skippedBecauseSeedExists: Bool
}

struct PerformanceSeedPreview {
    let habitCount: Int
    let approximateEntryCount: Int
}

struct PerformanceSeedRemovalResult {
    let removedHabitCount: Int
    let removedExperimentCount: Int
}

enum PerformanceSeedService {
    private static let seedTitlePrefix = "[Perf]"

    static var preview: PerformanceSeedPreview {
        PerformanceSeedPreview(
            habitCount: seedSpecs().count,
            // Medido sobre el seed real: 5 specs x 365 días, menos los días fuera de agenda y
            // los huecos deliberados, más los impulsos del hábito de dejar. `PerformanceSeedServiceTests`
            // falla si el dataset se aleja de este número.
            approximateEntryCount: 1_480
        )
    }

    static func hasSeed(in habits: [Habit]) -> Bool {
        habits.contains(where: isSeedHabit)
    }

    @discardableResult
    static func seedIfNeeded(
        existingHabits: [Habit],
        reference: Date = .now,
        modelContext: ModelContext
    ) throws -> PerformanceSeedResult {
        guard hasSeed(in: existingHabits) == false else {
            return PerformanceSeedResult(
                insertedHabitCount: 0,
                insertedEntryCount: 0,
                skippedBecauseSeedExists: true
            )
        }

        let referenceDay = AppCalendar.startOfDay(for: reference)
        let createdAt = AppCalendar.current.date(byAdding: .day, value: -364, to: referenceDay) ?? referenceDay
        let specs = seedSpecs()
        var insertedEntryCount = 0

        for spec in specs {
            let habit = Habit(
                title: "\(seedTitlePrefix) \(spec.title)",
                note: "Datos sintéticos para perfilar Week e Insights.",
                cue: spec.cue,
                iconName: spec.iconName,
                colorHex: spec.colorHex,
                targetDaysPerWeek: spec.targetDaysPerWeek,
                activeDaysOfWeek: spec.activeDays,
                trackingKind: spec.trackingKind,
                measurementUnit: spec.measurementUnit,
                targetValuePerSession: spec.targetValue,
                scheduleKind: spec.scheduleKind,
                direction: spec.direction,
                allowsWeeklyFreeze: true,
                createdAt: createdAt
            )
            modelContext.insert(habit)

            for dayIndex in 0..<365 {
                guard let day = AppCalendar.current.date(byAdding: .day, value: dayIndex, to: createdAt),
                      habit.isLoggable(on: day) else {
                    continue
                }

                insertedEntryCount += insertEntries(
                    for: habit,
                    day: day,
                    dayIndex: dayIndex,
                    spec: spec,
                    modelContext: modelContext
                )
            }
        }

        try modelContext.save()

        return PerformanceSeedResult(
            insertedHabitCount: specs.count,
            insertedEntryCount: insertedEntryCount,
            skippedBecauseSeedExists: false
        )
    }

    @discardableResult
    static func removeSeed(
        existingHabits: [Habit],
        modelContext: ModelContext
    ) throws -> PerformanceSeedRemovalResult {
        let seedHabits = existingHabits.filter(isSeedHabit)
        let seedHabitIDs = Set(seedHabits.map(\.id))

        // `HabitExperiment` apunta al hábito por `habitID`, no por relación, así que el borrado
        // en cascada no lo alcanza. Sin esto queda un experimento huérfano que sigue mostrando
        // el título `[Perf]` en Insights y que ya no se puede resolver desde la app.
        let seedExperiments = try modelContext
            .fetch(FetchDescriptor<HabitExperiment>())
            .filter { seedHabitIDs.contains($0.habitID) }

        for experiment in seedExperiments {
            modelContext.delete(experiment)
        }

        for habit in seedHabits {
            modelContext.delete(habit)
        }

        try modelContext.save()

        return PerformanceSeedRemovalResult(
            removedHabitCount: seedHabits.count,
            removedExperimentCount: seedExperiments.count
        )
    }

    private static func isSeedHabit(_ habit: Habit) -> Bool {
        habit.title.hasPrefix(seedTitlePrefix)
    }

    private static func seedSpecs() -> [PerformanceSeedSpec] {
        [
            PerformanceSeedSpec(
                title: "Caminar",
                cue: "Después de comer",
                iconName: "figure.walk",
                colorHex: "#2E7D32",
                targetDaysPerWeek: 7,
                activeDays: Set(Weekday.ordered),
                scheduleKind: .daily,
                trackingKind: .check,
                measurementUnit: .none,
                targetValue: 1,
                direction: .build,
                completionOffset: 0,
                baseHour: 8
            ),
            PerformanceSeedSpec(
                title: "Leer",
                cue: "Antes de dormir",
                iconName: "book.fill",
                colorHex: "#1565C0",
                targetDaysPerWeek: 5,
                activeDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                scheduleKind: .specificDays,
                trackingKind: .quantity,
                measurementUnit: .pages,
                targetValue: 10,
                direction: .build,
                completionOffset: 1,
                baseHour: 21
            ),
            PerformanceSeedSpec(
                title: "Estirar",
                cue: "Al despertar",
                iconName: "figure.flexibility",
                colorHex: "#6A1B9A",
                targetDaysPerWeek: 4,
                activeDays: [.monday, .wednesday, .friday, .sunday],
                scheduleKind: .specificDays,
                trackingKind: .check,
                measurementUnit: .none,
                targetValue: 1,
                direction: .build,
                completionOffset: 2,
                baseHour: 7
            ),
            PerformanceSeedSpec(
                title: "Estudio profundo",
                cue: "Bloque de tarde",
                iconName: "brain.head.profile",
                colorHex: "#AD6A00",
                targetDaysPerWeek: 3,
                activeDays: Set(Weekday.ordered),
                scheduleKind: .timesPerWeek,
                trackingKind: .quantity,
                measurementUnit: .minutes,
                targetValue: 45,
                direction: .build,
                completionOffset: 3,
                baseHour: 17
            ),
            PerformanceSeedSpec(
                title: "Sin redes tarde",
                cue: "Después de cenar",
                iconName: "iphone.slash",
                colorHex: "#C62828",
                targetDaysPerWeek: 7,
                activeDays: Set(Weekday.ordered),
                scheduleKind: .daily,
                trackingKind: .check,
                measurementUnit: .none,
                targetValue: 1,
                direction: .break,
                completionOffset: 4,
                baseHour: 20
            )
        ]
    }

    private static func insertEntries(
        for habit: Habit,
        day: Date,
        dayIndex: Int,
        spec: PerformanceSeedSpec,
        modelContext: ModelContext
    ) -> Int {
        if spec.direction == .break {
            return insertBreakHabitEntries(
                for: habit,
                day: day,
                dayIndex: dayIndex,
                spec: spec,
                modelContext: modelContext
            )
        }

        if (dayIndex + spec.completionOffset) % 17 == 0 {
            modelContext.insert(
                HabitEntry(
                    date: day,
                    completedAt: nil,
                    source: .today,
                    kind: .minimum,
                    completedCount: 0,
                    value: 0,
                    habit: habit
                )
            )
            return 1
        }

        if (dayIndex + spec.completionOffset) % 11 == 0 {
            modelContext.insert(
                HabitEntry(
                    date: day,
                    completedAt: nil,
                    source: .today,
                    kind: .skipped,
                    completedCount: 0,
                    value: 0,
                    habit: habit
                )
            )
            return 1
        }

        if (dayIndex + spec.completionOffset) % 7 == 0 {
            modelContext.insert(
                HabitEntry(
                    date: day,
                    completedAt: nil,
                    source: .today,
                    kind: .missed,
                    completedCount: 0,
                    value: 0,
                    failureReason: failureReason(for: dayIndex),
                    habit: habit
                )
            )
            return 1
        }

        guard (dayIndex + spec.completionOffset) % 5 != 0 else { return 0 }

        let value = spec.trackingKind == .quantity
            ? spec.targetValue + Double((dayIndex + spec.completionOffset) % 4)
            : 1
        modelContext.insert(
            HabitEntry(
                date: day,
                completedAt: timestamp(on: day, hour: spec.baseHour + (dayIndex % 2)),
                source: dayIndex % 13 == 0 ? .focusSession : .today,
                kind: .completed,
                completedCount: Int(value.rounded()),
                value: value,
                habit: habit
            )
        )
        return 1
    }

    private static func insertBreakHabitEntries(
        for habit: Habit,
        day: Date,
        dayIndex: Int,
        spec: PerformanceSeedSpec,
        modelContext: ModelContext
    ) -> Int {
        var inserted = 0

        if dayIndex % 6 != 0 {
            modelContext.insert(
                HabitEntry(
                    date: day,
                    completedAt: timestamp(on: day, hour: spec.baseHour),
                    source: .today,
                    kind: .completed,
                    completedCount: 1,
                    value: 1,
                    habit: habit
                )
            )
            inserted += 1
        } else {
            modelContext.insert(
                HabitEntry(
                    date: day,
                    completedAt: timestamp(on: day, hour: spec.baseHour + 1),
                    source: .today,
                    kind: .slip,
                    completedCount: 0,
                    value: 0,
                    slipTrigger: slipTrigger(for: dayIndex),
                    habit: habit
                )
            )
            inserted += 1
        }

        if dayIndex % 4 == 0 {
            modelContext.insert(
                HabitEntry(
                    date: day,
                    completedAt: timestamp(on: day, hour: 19 + (dayIndex % 3)),
                    source: .today,
                    kind: .urge,
                    completedCount: 0,
                    value: 0,
                    slipTrigger: slipTrigger(for: dayIndex + 1),
                    habit: habit
                )
            )
            inserted += 1
        }

        return inserted
    }

    private static func timestamp(on day: Date, hour: Int) -> Date {
        AppCalendar.current.date(bySettingHour: hour, minute: 20, second: 0, of: day) ?? day
    }

    private static func failureReason(for index: Int) -> HabitFailureReason {
        let reasons: [HabitFailureReason] = [.forgot, .badTiming, .lowEnergy, .tooDifficult, .other]
        return reasons[index % reasons.count]
    }

    private static func slipTrigger(for index: Int) -> SlipTrigger {
        let triggers: [SlipTrigger] = [.stress, .boredom, .social, .fatigue, .craving, .other]
        return triggers[index % triggers.count]
    }
}

private struct PerformanceSeedSpec {
    let title: String
    let cue: String
    let iconName: String
    let colorHex: String
    let targetDaysPerWeek: Int
    let activeDays: Set<Weekday>
    let scheduleKind: HabitScheduleKind
    let trackingKind: HabitTrackingKind
    let measurementUnit: HabitMeasurementUnit
    let targetValue: Double
    let direction: HabitDirection
    let completionOffset: Int
    let baseHour: Int
}
#endif
