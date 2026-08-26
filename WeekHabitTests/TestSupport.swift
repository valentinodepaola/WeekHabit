import Foundation
import SwiftData
@testable import WeekHabit

@MainActor
struct TestStore {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let schema = Schema(versionedSchema: SchemaV17.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: configuration)
        context = container.mainContext
    }

    func insert(_ habit: Habit) {
        context.insert(habit)
    }

    func save() throws {
        try context.save()
    }
}

@MainActor
enum TestFactory {
    static func date(
        year: Int = 2026,
        month: Int = 6,
        day: Int,
        hour: Int = 12
    ) -> Date {
        AppCalendar.current.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour)
        )!
    }

    static func habit(
        title: String = "Test habit",
        schedule: HabitScheduleKind = .daily,
        activeDays: Set<Weekday>? = nil,
        targetDaysPerWeek: Int = 7,
        tracking: HabitTrackingKind = .check,
        targetValue: Double = 1,
        direction: HabitDirection = .build,
        allowsWeeklyFreeze: Bool = true,
        createdAt: Date? = nil
    ) -> Habit {
        Habit(
            title: title,
            targetDaysPerWeek: targetDaysPerWeek,
            activeDaysOfWeek: activeDays ?? Set(Weekday.ordered),
            trackingKind: tracking,
            targetValuePerSession: targetValue,
            scheduleKind: schedule,
            direction: direction,
            allowsWeeklyFreeze: allowsWeeklyFreeze,
            createdAt: createdAt ?? date(day: 1)
        )
    }

    @discardableResult
    static func entry(
        _ kind: EntryKind,
        habit: Habit,
        date: Date,
        value: Double = 0
    ) -> HabitEntry {
        let entry = HabitEntry(
            date: date,
            completedAt: date,
            source: .today,
            kind: kind,
            completedCount: Int(value.rounded()),
            value: value,
            habit: habit
        )
        habit.entries.append(entry)
        return entry
    }
}

// MARK: - Historial sintético para mediciones

/// Genera historiales grandes y deterministas para las pruebas de rendimiento.
///
/// Replica la forma de `PerformanceSeedService` — misma mezcla de estados diarios — pero
/// parametrizada por cantidad de hábitos y días de historial, para poder medir cómo escala
/// cada métrica. Sin aleatoriedad: la misma entrada produce siempre el mismo dataset.
@MainActor
enum TestHistoryFactory {
    /// Cada cuarto hábito es de tipo break, para que las métricas de urges y slips
    /// tengan datos con los que trabajar.
    private static let breakHabitStride = 4

    @discardableResult
    static func seedHistory(
        habitCount: Int,
        days: Int,
        reference: Date,
        in store: TestStore
    ) throws -> [Habit] {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        let firstDay = AppCalendar.current.date(
            byAdding: .day,
            value: -(days - 1),
            to: referenceDay
        ) ?? referenceDay

        let habits = (0..<habitCount).map { habitIndex -> Habit in
            let habit = makeHabit(index: habitIndex, createdAt: firstDay)
            store.context.insert(habit)
            return habit
        }

        for (habitIndex, habit) in habits.enumerated() {
            for dayOffset in 0..<days {
                guard let day = AppCalendar.current.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: firstDay
                ), habit.isLoggable(on: day) else {
                    continue
                }

                insertEntries(
                    for: habit,
                    on: day,
                    dayIndex: dayOffset + habitIndex,
                    isBreakHabit: habit.direction == .break,
                    in: store
                )
            }
        }

        try store.save()
        return habits
    }

    // MARK: - Construcción

    private static func makeHabit(index: Int, createdAt: Date) -> Habit {
        let isBreakHabit = index % breakHabitStride == breakHabitStride - 1
        let isQuantity = !isBreakHabit && index % 3 == 1

        return Habit(
            title: "Hábito de medición \(index)",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            trackingKind: isQuantity ? .quantity : .check,
            measurementUnit: isQuantity ? .minutes : .none,
            targetValuePerSession: isQuantity ? 30 : 1,
            scheduleKind: .daily,
            direction: isBreakHabit ? .break : .build,
            allowsWeeklyFreeze: true,
            createdAt: createdAt
        )
    }

    private static func insertEntries(
        for habit: Habit,
        on day: Date,
        dayIndex: Int,
        isBreakHabit: Bool,
        in store: TestStore
    ) {
        if isBreakHabit {
            insertBreakEntries(for: habit, on: day, dayIndex: dayIndex, in: store)
            return
        }

        // Mezcla determinista: la mayoría completados, con huecos periódicos de cada
        // estado para que las métricas de racha y consistencia tengan variedad real.
        let kind: EntryKind
        switch dayIndex {
        case let index where index % 17 == 0: kind = .minimum
        case let index where index % 11 == 0: kind = .skipped
        case let index where index % 7 == 0: kind = .missed
        case let index where index % 5 == 0: return
        default: kind = .completed
        }

        let value: Double = kind == .completed ? (habit.targetValuePerSession ?? 1) : 0
        insert(
            HabitEntry(
                date: day,
                completedAt: kind == .completed ? timestamp(on: day, hour: 8 + dayIndex % 12) : nil,
                source: dayIndex % 13 == 0 ? .focusSession : .today,
                kind: kind,
                completedCount: Int(value.rounded()),
                value: value,
                failureReason: kind == .missed ? .forgot : nil,
                habit: habit
            ),
            in: store
        )
    }

    private static func insertBreakEntries(
        for habit: Habit,
        on day: Date,
        dayIndex: Int,
        in store: TestStore
    ) {
        let slipped = dayIndex % 6 == 0
        insert(
            HabitEntry(
                date: day,
                completedAt: timestamp(on: day, hour: 20),
                source: .today,
                kind: slipped ? .slip : .completed,
                completedCount: slipped ? 0 : 1,
                value: slipped ? 0 : 1,
                slipTrigger: slipped ? .stress : nil,
                habit: habit
            ),
            in: store
        )

        guard dayIndex % 4 == 0 else { return }

        insert(
            HabitEntry(
                date: day,
                completedAt: timestamp(on: day, hour: 19 + dayIndex % 3),
                source: .today,
                kind: .urge,
                completedCount: 0,
                value: 0,
                slipTrigger: .craving,
                habit: habit
            ),
            in: store
        )
    }

    private static func insert(_ entry: HabitEntry, in store: TestStore) {
        store.context.insert(entry)
    }

    private static func timestamp(on day: Date, hour: Int) -> Date {
        AppCalendar.current.date(bySettingHour: hour, minute: 20, second: 0, of: day) ?? day
    }
}
