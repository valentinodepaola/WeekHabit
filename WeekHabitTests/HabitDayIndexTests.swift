import SwiftData
import XCTest
@testable import WeekHabit

/// `HabitDayIndex` reemplaza los escaneos por día del dominio, así que lo único que
/// importa de él es que responda **exactamente** lo mismo que la API que sustituye.
///
/// Estas pruebas recorren día por día un historial completo y comparan cada predicado
/// contra su equivalente en `Habit`. Si el índice difiere en un solo día, fallan.
@MainActor
final class HabitDayIndexTests: XCTestCase {

    private let reference = TestFactory.date(day: 15)

    func testIndexMatchesHabitAPIForABuildHabit() throws {
        let store = try TestStore()
        let habits = try TestHistoryFactory.seedHistory(
            habitCount: 1,
            days: 200,
            reference: reference,
            in: store
        )
        let habit = try XCTUnwrap(habits.first)

        assertIndexMatchesHabit(habit, days: 200)
    }

    func testIndexMatchesHabitAPIForABreakHabitWithSlipsAndUrges() throws {
        let store = try TestStore()
        // El cuarto hábito del generador es de tipo break: trae slips y urges.
        let habits = try TestHistoryFactory.seedHistory(
            habitCount: 4,
            days: 120,
            reference: reference,
            in: store
        )
        let breakHabit = try XCTUnwrap(habits.first(where: \.isBreakHabit))

        assertIndexMatchesHabit(breakHabit, days: 120)
    }

    func testIndexMatchesHabitAPIForFreezeProtectedDays() throws {
        let store = try TestStore()
        let habit = TestFactory.habit(createdAt: TestFactory.date(day: 1))
        store.insert(habit)

        for day in [3, 7, 11] {
            let protectedDate = TestFactory.date(day: day)
            store.context.insert(StreakFreeze(habit: habit, protectedDate: protectedDate))
        }
        try store.save()

        let index = HabitDayIndex(habit)
        for day in 1...15 {
            let date = TestFactory.date(day: day)
            XCTAssertEqual(
                index.isFreezeProtected(on: date),
                habit.isFreezeProtected(on: date),
                "isFreezeProtected difiere el día \(day)"
            )
            XCTAssertEqual(
                index.preservesStreakWithoutCompletion(on: date),
                habit.preservesStreakWithoutCompletion(on: date),
                "preservesStreakWithoutCompletion difiere el día \(day)"
            )
        }
    }

    func testFreezesAreIgnoredWhenTheHabitDoesNotAllowThem() throws {
        let store = try TestStore()
        let habit = TestFactory.habit(allowsWeeklyFreeze: false, createdAt: TestFactory.date(day: 1))
        store.insert(habit)
        let protectedDate = TestFactory.date(day: 3)
        store.context.insert(StreakFreeze(habit: habit, protectedDate: protectedDate))
        try store.save()

        let index = HabitDayIndex(habit)

        XCTAssertFalse(index.isFreezeProtected(on: protectedDate))
        XCTAssertEqual(
            index.isFreezeProtected(on: protectedDate),
            habit.isFreezeProtected(on: protectedDate)
        )
    }

    // MARK: - Helper

    /// Compara cada predicado del índice contra el de `Habit`, día por día.
    private func assertIndexMatchesHabit(
        _ habit: Habit,
        days: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let index = HabitDayIndex(habit)
        let firstDay = AppCalendar.current.date(
            byAdding: .day,
            value: -(days - 1),
            to: AppCalendar.startOfDay(for: reference)
        )!

        for dayOffset in 0..<days {
            guard let day = AppCalendar.current.date(byAdding: .day, value: dayOffset, to: firstDay) else {
                continue
            }
            let label = "día \(dayOffset)"

            XCTAssertEqual(index.isCompleted(on: day), habit.isCompleted(on: day), "isCompleted, \(label)", file: file, line: line)
            XCTAssertEqual(index.isMinimumCompleted(on: day), habit.isMinimumCompleted(on: day), "isMinimumCompleted, \(label)", file: file, line: line)
            XCTAssertEqual(index.isSkipped(on: day), habit.isSkipped(on: day), "isSkipped, \(label)", file: file, line: line)
            XCTAssertEqual(index.isMissed(on: day), habit.isMissed(on: day), "isMissed, \(label)", file: file, line: line)
            XCTAssertEqual(index.isSlip(on: day), habit.isSlip(on: day), "isSlip, \(label)", file: file, line: line)
            XCTAssertEqual(index.hasUrge(on: day), habit.hasUrge(on: day), "hasUrge, \(label)", file: file, line: line)
            XCTAssertEqual(index.hasAnyEntry(on: day), habit.hasAnyEntry(on: day), "hasAnyEntry, \(label)", file: file, line: line)
            XCTAssertEqual(index.totalValue(on: day), habit.totalValue(on: day), "totalValue, \(label)", file: file, line: line)
            XCTAssertEqual(index.isFreezeProtected(on: day), habit.isFreezeProtected(on: day), "isFreezeProtected, \(label)", file: file, line: line)
            XCTAssertEqual(index.preservesStreakWithoutCompletion(on: day), habit.preservesStreakWithoutCompletion(on: day), "preservesStreak, \(label)", file: file, line: line)
            XCTAssertEqual(index.isTrustedCompleted(on: day), habit.isTrustedCompleted(on: day), "isTrustedCompleted, \(label)", file: file, line: line)
            XCTAssertEqual(index.isManualCompleted(on: day), habit.isManualCompleted(on: day), "isManualCompleted, \(label)", file: file, line: line)
        }
    }
}
