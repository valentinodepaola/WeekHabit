import XCTest
@testable import WeekHabit

@MainActor
final class TodayCollectionsTests: XCTestCase {

    // MARK: - loggableToday

    func testLoggableTodayFiltersInactiveSchedule() throws {
        let monday = TestFactory.date(day: 1)
        let dailyHabit = TestFactory.habit()
        let mondayOnly = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday]
        )
        let tuesdayOnly = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.tuesday]
        )

        let loggable = [dailyHabit, mondayOnly, tuesdayOnly].loggableToday(on: monday)

        XCTAssertEqual(loggable.count, 2)
        XCTAssertTrue(loggable.contains { $0 === dailyHabit })
        XCTAssertTrue(loggable.contains { $0 === mondayOnly })
    }

    func testLoggableTodayExcludesHabitsEndingBeforeReference() throws {
        let creation = TestFactory.date(day: 1)
        let endDate = TestFactory.date(day: 5)
        let reference = TestFactory.date(day: 10)

        let active = TestFactory.habit(createdAt: creation)
        let finished = TestFactory.habit(createdAt: creation)
        finished.endsAt = endDate

        let loggable = [active, finished].loggableToday(on: reference)

        XCTAssertEqual(loggable.count, 1)
        XCTAssertTrue(loggable.contains { $0 === active })
    }

    func testLoggableTodayIncludesHabitOnItsEndDate() throws {
        let day = TestFactory.date(day: 5)
        let habit = TestFactory.habit()
        habit.endsAt = day

        XCTAssertEqual([habit].loggableToday(on: day).count, 1)
    }

    // MARK: - Partitions are mutually exclusive

    func testPendingCompletedSkippedSlippedAreMutuallyExclusiveAndComplete() throws {
        let day = TestFactory.date(day: 1)

        let pending = TestFactory.habit()
        let completed = TestFactory.habit()
        TestFactory.entry(.completed, habit: completed, date: day, value: 1)
        let skipped = TestFactory.habit()
        TestFactory.entry(.skipped, habit: skipped, date: day)
        let slipped = TestFactory.habit(direction: .break)
        TestFactory.entry(.slip, habit: slipped, date: day)

        let todayHabits = [pending, completed, skipped, slipped].loggableToday(on: day)

        let pendingSet = Set(todayHabits.pendingToday(on: day).map { ObjectIdentifier($0) })
        let completedSet = Set(todayHabits.completedToday(on: day).map { ObjectIdentifier($0) })
        let skippedSet = Set(todayHabits.skippedToday(on: day).map { ObjectIdentifier($0) })
        let slippedSet = Set(todayHabits.slippedToday(on: day).map { ObjectIdentifier($0) })

        XCTAssertTrue(pendingSet.isDisjoint(with: completedSet))
        XCTAssertTrue(pendingSet.isDisjoint(with: skippedSet))
        XCTAssertTrue(pendingSet.isDisjoint(with: slippedSet))
        XCTAssertTrue(completedSet.isDisjoint(with: skippedSet))
        XCTAssertTrue(completedSet.isDisjoint(with: slippedSet))
        XCTAssertTrue(skippedSet.isDisjoint(with: slippedSet))

        let union = pendingSet.union(completedSet).union(skippedSet).union(slippedSet)
        let allIDs = Set(todayHabits.map { ObjectIdentifier($0) })
        XCTAssertEqual(union, allIDs)
    }

    func testCompletedTodayIncludesMinimumOnlyEntries() throws {
        let day = TestFactory.date(day: 1)
        let habit = TestFactory.habit()
        TestFactory.entry(.minimum, habit: habit, date: day)

        let todayHabits = [habit].loggableToday(on: day)

        XCTAssertTrue(todayHabits.completedToday(on: day).contains { $0 === habit })
        XCTAssertFalse(todayHabits.pendingToday(on: day).contains { $0 === habit })
    }

    func testFlexibleHabitMeetingWeeklyTargetIsCompletedEveryDay() throws {
        let monday = TestFactory.date(day: 1)
        let tuesday = TestFactory.date(day: 2)
        let wednesday = TestFactory.date(day: 3)

        let habit = TestFactory.habit(
            schedule: .timesPerWeek,
            targetDaysPerWeek: 2
        )
        TestFactory.entry(.completed, habit: habit, date: monday, value: 1)
        TestFactory.entry(.completed, habit: habit, date: tuesday, value: 1)

        let todayHabits = [habit].loggableToday(on: wednesday)

        XCTAssertTrue(todayHabits.completedToday(on: wednesday).contains { $0 === habit })
    }

    // MARK: - dailyProgress

    func testDailyProgressIsZeroWithNoHabits() throws {
        let day = TestFactory.date(day: 1)
        let habits: [Habit] = []
        XCTAssertEqual(habits.dailyProgress(on: day), 0)
    }

    func testDailyProgressIsOneWhenAllHabitsCompleted() throws {
        let day = TestFactory.date(day: 1)
        let a = TestFactory.habit()
        let b = TestFactory.habit()
        TestFactory.entry(.completed, habit: a, date: day, value: 1)
        TestFactory.entry(.completed, habit: b, date: day, value: 1)

        let todayHabits = [a, b].loggableToday(on: day)
        XCTAssertEqual(todayHabits.dailyProgress(on: day), 1)
    }

    func testDailyProgressIgnoresSkippedHabitsInActiveCount() throws {
        let day = TestFactory.date(day: 1)
        let completed = TestFactory.habit()
        let skipped = TestFactory.habit()
        let pending = TestFactory.habit()
        TestFactory.entry(.completed, habit: completed, date: day, value: 1)
        TestFactory.entry(.skipped, habit: skipped, date: day)

        let todayHabits = [completed, skipped, pending].loggableToday(on: day)

        // 1 completado de 2 activos (pending + completed; skipped no cuenta)
        XCTAssertEqual(todayHabits.activeCountToday(on: day), 2)
        XCTAssertEqual(todayHabits.completedCountToday(on: day), 1)
        XCTAssertEqual(todayHabits.dailyProgress(on: day), 0.5)
    }

    func testDailyProgressIsOneWhenOnlyActiveHabitIsCompleted() throws {
        let day = TestFactory.date(day: 1)
        let completed = TestFactory.habit()
        let skipped = TestFactory.habit()
        TestFactory.entry(.completed, habit: completed, date: day, value: 1)
        TestFactory.entry(.skipped, habit: skipped, date: day)

        let todayHabits = [completed, skipped].loggableToday(on: day)
        XCTAssertEqual(todayHabits.dailyProgress(on: day), 1)
    }
}
