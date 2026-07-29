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

    // MARK: - todayPartition

    /// El contrato de `todayPartition` es ser indistinguible de llamar a las siete funciones
    /// sueltas. Si alguna vez difieren, la vista muestra algo distinto de lo que dicen los
    /// tests de arriba, que es justo lo que este test evita.
    private func assertPartitionMatchesIndividualFunctions(
        _ habits: [Habit],
        on date: Date,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let partition = habits.todayPartition(on: date)

        XCTAssertEqual(
            partition.pending.map(\.id), habits.pendingToday(on: date).map(\.id),
            "pending", file: file, line: line
        )
        XCTAssertEqual(
            partition.completed.map(\.id), habits.completedToday(on: date).map(\.id),
            "completed", file: file, line: line
        )
        XCTAssertEqual(
            partition.skipped.map(\.id), habits.skippedToday(on: date).map(\.id),
            "skipped", file: file, line: line
        )
        XCTAssertEqual(
            partition.slipped.map(\.id), habits.slippedToday(on: date).map(\.id),
            "slipped", file: file, line: line
        )
        XCTAssertEqual(
            partition.completedCount, habits.completedCountToday(on: date),
            "completedCount", file: file, line: line
        )
        XCTAssertEqual(
            partition.activeCount, habits.activeCountToday(on: date),
            "activeCount", file: file, line: line
        )
        XCTAssertEqual(
            partition.progress, habits.dailyProgress(on: date),
            accuracy: 0.0001, "progress", file: file, line: line
        )
    }

    func testTodayPartitionMatchesIndividualFunctionsAcrossStates() throws {
        let day = TestFactory.date(day: 1)

        let pending = TestFactory.habit()
        let completed = TestFactory.habit()
        let minimum = TestFactory.habit()
        let skipped = TestFactory.habit()
        let slipped = TestFactory.habit()
        TestFactory.entry(.completed, habit: completed, date: day, value: 1)
        TestFactory.entry(.minimum, habit: minimum, date: day)
        TestFactory.entry(.skipped, habit: skipped, date: day)
        TestFactory.entry(.slip, habit: slipped, date: day)

        let todayHabits = [pending, completed, minimum, skipped, slipped]
            .loggableToday(on: day)

        assertPartitionMatchesIndividualFunctions(todayHabits, on: day)
        XCTAssertEqual(todayHabits.todayPartition(on: day).pending.count, 1)
        XCTAssertEqual(todayHabits.todayPartition(on: day).completed.count, 2)
    }

    /// La agenda flexible es el caso que obliga a compartir el índice: su regla de sección
    /// mira la semana entera, no el día.
    func testTodayPartitionMatchesIndividualFunctionsForFlexibleSchedule() throws {
        let monday = TestFactory.date(day: 1)
        let wednesday = TestFactory.date(day: 3)

        let metWeeklyGoal = TestFactory.habit(schedule: .timesPerWeek, targetDaysPerWeek: 2)
        TestFactory.entry(.completed, habit: metWeeklyGoal, date: monday, value: 1)
        TestFactory.entry(.completed, habit: metWeeklyGoal, date: wednesday, value: 1)

        let belowWeeklyGoal = TestFactory.habit(schedule: .timesPerWeek, targetDaysPerWeek: 3)
        TestFactory.entry(.completed, habit: belowWeeklyGoal, date: monday, value: 1)

        let reference = TestFactory.date(day: 4)
        let todayHabits = [metWeeklyGoal, belowWeeklyGoal].loggableToday(on: reference)

        assertPartitionMatchesIndividualFunctions(todayHabits, on: reference)

        // La meta semanal cumplida cuenta como hecho aunque hoy no haya entrada.
        let partition = todayHabits.todayPartition(on: reference)
        XCTAssertEqual(partition.completed.map(\.id), [metWeeklyGoal.id])
        XCTAssertEqual(partition.pending.map(\.id), [belowWeeklyGoal.id])
    }

    /// Descanso y slip son filtros independientes, no excluyentes: un hábito con ambos
    /// aparece en las dos secciones. Es raro, pero el comportamiento previo era ese y la
    /// partición no debe cambiarlo por su cuenta.
    func testTodayPartitionMatchesIndividualFunctionsWhenSkippedAndSlippedOverlap() throws {
        let day = TestFactory.date(day: 1)
        let both = TestFactory.habit()
        TestFactory.entry(.skipped, habit: both, date: day)
        TestFactory.entry(.slip, habit: both, date: day)

        let todayHabits = [both, TestFactory.habit()].loggableToday(on: day)

        assertPartitionMatchesIndividualFunctions(todayHabits, on: day)
    }

    func testTodayPartitionOnEmptyCollectionMatchesIndividualFunctions() throws {
        let day = TestFactory.date(day: 1)
        let empty: [Habit] = []

        assertPartitionMatchesIndividualFunctions(empty, on: day)
        XCTAssertEqual(empty.todayPartition(on: day).progress, 0)
    }
}
