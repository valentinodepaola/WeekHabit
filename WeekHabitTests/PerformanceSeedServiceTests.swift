#if DEBUG
import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class PerformanceSeedServiceTests: XCTestCase {
    func testHasSeedRecognizesOnlyPerformancePrefix() {
        let regularHabit = makeHabit(title: "Preparar [Perf] reporte")
        let seedHabit = makeHabit(title: "[Perf] Caminar")

        XCTAssertFalse(PerformanceSeedService.hasSeed(in: [regularHabit]))
        XCTAssertTrue(PerformanceSeedService.hasSeed(in: [regularHabit, seedHabit]))
    }

    func testSeedPersistsPreviewHabitCountAndReportedEntries() throws {
        let store = try TestStore()

        let result = try PerformanceSeedService.seedIfNeeded(
            existingHabits: [],
            reference: TestFactory.date(day: 30),
            modelContext: store.context
        )

        let habits = try store.context.fetch(FetchDescriptor<Habit>())
        let entries = try store.context.fetch(FetchDescriptor<HabitEntry>())
        XCTAssertFalse(result.skippedBecauseSeedExists)
        XCTAssertEqual(result.insertedHabitCount, PerformanceSeedService.preview.habitCount)
        XCTAssertEqual(habits.count, result.insertedHabitCount)
        XCTAssertEqual(entries.count, result.insertedEntryCount)
        XCTAssertLessThanOrEqual(
            abs(result.insertedEntryCount - PerformanceSeedService.preview.approximateEntryCount),
            20,
            "el estimado mostrado antes de confirmar debe mantenerse cerca del seed real"
        )
    }

    func testSeedSkipsWhenPerformanceDataAlreadyExists() throws {
        let store = try TestStore()
        let reference = TestFactory.date(day: 30)
        _ = try PerformanceSeedService.seedIfNeeded(
            existingHabits: [],
            reference: reference,
            modelContext: store.context
        )
        let existingHabits = try store.context.fetch(FetchDescriptor<Habit>())
        let existingEntries = try store.context.fetch(FetchDescriptor<HabitEntry>())

        let result = try PerformanceSeedService.seedIfNeeded(
            existingHabits: existingHabits,
            reference: reference,
            modelContext: store.context
        )

        XCTAssertTrue(result.skippedBecauseSeedExists)
        XCTAssertEqual(result.insertedHabitCount, 0)
        XCTAssertEqual(result.insertedEntryCount, 0)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Habit>()).count, existingHabits.count)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<HabitEntry>()).count, existingEntries.count)
    }

    func testRemoveSeedDeletesSeedEntriesAndPreservesRealData() throws {
        let store = try TestStore()
        let reference = TestFactory.date(day: 30)
        let realHabit = makeHabit(title: "Caminar de verdad")
        store.context.insert(realHabit)
        let realEntry = TestFactory.entry(.completed, habit: realHabit, date: reference, value: 1)
        let realFreeze = StreakFreeze(habit: realHabit, protectedDate: reference)
        store.context.insert(realFreeze)
        try store.save()

        _ = try PerformanceSeedService.seedIfNeeded(
            existingHabits: [realHabit],
            reference: reference,
            modelContext: store.context
        )
        let allHabits = try store.context.fetch(FetchDescriptor<Habit>())

        let result = try PerformanceSeedService.removeSeed(
            existingHabits: allHabits,
            modelContext: store.context
        )

        let remainingHabits = try store.context.fetch(FetchDescriptor<Habit>())
        let remainingEntries = try store.context.fetch(FetchDescriptor<HabitEntry>())
        let remainingFreezes = try store.context.fetch(FetchDescriptor<StreakFreeze>())
        XCTAssertEqual(result.removedHabitCount, PerformanceSeedService.preview.habitCount)
        XCTAssertEqual(remainingHabits.map(\.id), [realHabit.id])
        XCTAssertEqual(remainingEntries.map(\.id), [realEntry.id])
        XCTAssertEqual(remainingFreezes.map(\.id), [realFreeze.id])
    }

    func testRemoveSeedWithoutSeedReturnsZeroAndPreservesStore() throws {
        let store = try TestStore()
        let realHabit = makeHabit(title: "Leer")
        store.context.insert(realHabit)
        try store.save()

        let result = try PerformanceSeedService.removeSeed(
            existingHabits: [realHabit],
            modelContext: store.context
        )

        XCTAssertEqual(result.removedHabitCount, 0)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Habit>()).map(\.id), [realHabit.id])
    }

    private func makeHabit(title: String) -> Habit {
        Habit(
            title: title,
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            scheduleKind: .daily
        )
    }
}
#endif
