import XCTest
@testable import WeekHabit

/// `TodayViewData` es lo que antes eran nueve propiedades computadas dentro de `TodayView`,
/// y por vivir en la vista no se podían testear. Al ser un value type, acá sí.
@MainActor
final class TodayViewDataTests: XCTestCase {

    private func makeData(
        habits: [Habit],
        streakFreezes: [StreakFreeze] = [],
        weeklyReviews: [WeeklyReview] = [],
        weekday: Weekday = .sunday,
        on date: Date
    ) -> TodayViewData {
        TodayViewData(
            habits: habits,
            streakFreezes: streakFreezes,
            weeklyReviews: weeklyReviews,
            weeklyReviewWeekday: weekday,
            referenceDate: date
        )
    }

    // MARK: - Particiones y contadores

    func testPartitionMatchesTheEquivalentCollectionCalls() throws {
        let day = TestFactory.date(day: 1)
        let pending = TestFactory.habit()
        let completed = TestFactory.habit()
        let skipped = TestFactory.habit()
        TestFactory.entry(.completed, habit: completed, date: day, value: 1)
        TestFactory.entry(.skipped, habit: skipped, date: day)

        let data = makeData(habits: [pending, completed, skipped], on: day)

        XCTAssertEqual(data.partition.pending.map(\.id), [pending.id])
        XCTAssertEqual(data.partition.completed.map(\.id), [completed.id])
        XCTAssertEqual(data.partition.skipped.map(\.id), [skipped.id])
        XCTAssertEqual(data.remainingCount, 1)
        XCTAssertEqual(data.partition.activeCount, 2)
        XCTAssertEqual(data.partition.progress, 0.5, accuracy: 0.0001)
        XCTAssertFalse(data.isEmpty)
    }

    func testHabitsOutsideTheScheduleAreExcluded() throws {
        let monday = TestFactory.date(day: 1)
        let mondayOnly = TestFactory.habit(schedule: .specificDays, activeDays: [.monday])
        let tuesdayOnly = TestFactory.habit(schedule: .specificDays, activeDays: [.tuesday])

        let data = makeData(habits: [mondayOnly, tuesdayOnly], on: monday)

        XCTAssertEqual(data.todayHabits.map(\.id), [mondayOnly.id])
    }

    func testIsEmptyWhenNoHabitIsLoggableToday() throws {
        let monday = TestFactory.date(day: 1)
        let tuesdayOnly = TestFactory.habit(schedule: .specificDays, activeDays: [.tuesday])

        let data = makeData(habits: [tuesdayOnly], on: monday)

        XCTAssertTrue(data.isEmpty)
        XCTAssertEqual(data.remainingCount, 0)
        XCTAssertEqual(data.partition.progress, 0)
    }

    // MARK: - Candidatos a sesión de enfoque

    func testFocusCandidatesExcludeRestedAndSlippedHabitsKeepingOriginalOrder() throws {
        let day = TestFactory.date(day: 1)
        let first = TestFactory.habit()
        let rested = TestFactory.habit()
        let third = TestFactory.habit()
        let slipped = TestFactory.habit()
        TestFactory.entry(.skipped, habit: rested, date: day)
        TestFactory.entry(.slip, habit: slipped, date: day)

        let data = makeData(habits: [first, rested, third, slipped], on: day)

        // El orden importa: la sesión de enfoque recorre los hábitos en secuencia.
        XCTAssertEqual(data.focusCandidateHabits.map(\.id), [first.id, third.id])
        XCTAssertTrue(data.hasFocusCandidates)
    }

    func testHasNoFocusCandidatesWhenEveryHabitIsRested() throws {
        let day = TestFactory.date(day: 1)
        let rested = TestFactory.habit()
        TestFactory.entry(.skipped, habit: rested, date: day)

        let data = makeData(habits: [rested], on: day)

        XCTAssertFalse(data.hasFocusCandidates)
    }

    // MARK: - Firma de sección

    func testSectionSignatureChangesWhenAHabitMovesBetweenSections() throws {
        let day = TestFactory.date(day: 1)
        let habit = TestFactory.habit()

        let before = makeData(habits: [habit], on: day).sectionSignature
        TestFactory.entry(.completed, habit: habit, date: day, value: 1)
        let after = makeData(habits: [habit], on: day).sectionSignature

        XCTAssertNotEqual(before, after)
    }

    func testSectionSignatureIsStableWhenNothingMoves() throws {
        let day = TestFactory.date(day: 1)
        let habits = [TestFactory.habit(), TestFactory.habit()]

        XCTAssertEqual(
            makeData(habits: habits, on: day).sectionSignature,
            makeData(habits: habits, on: day).sectionSignature
        )
    }

    // MARK: - Mañana

    func testTomorrowCountUsesTomorrowSchedule() throws {
        let monday = TestFactory.date(day: 1)
        let tuesdayOnly = TestFactory.habit(schedule: .specificDays, activeDays: [.tuesday])

        let data = makeData(habits: [tuesdayOnly], on: monday)

        XCTAssertTrue(data.isEmpty)
        XCTAssertEqual(data.tomorrowHabitsCount, 1)
    }
}
