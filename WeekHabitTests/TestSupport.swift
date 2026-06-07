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
            title: "Test habit",
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
