import XCTest
@testable import WeekHabit

@MainActor
final class HabitDomainTests: XCTestCase {
    func testSpecificDaysScheduleOnlyLogsSelectedWeekdays() {
        let monday = TestFactory.date(day: 1)
        let tuesday = TestFactory.date(day: 2)
        let habit = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday],
            targetDaysPerWeek: 1,
            createdAt: monday
        )

        XCTAssertTrue(habit.isLoggable(on: monday))
        XCTAssertFalse(habit.isLoggable(on: tuesday))
    }

    func testMinimumCountsForStreakButNotCompletion() {
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit(createdAt: date)
        TestFactory.entry(.minimum, habit: habit, date: date)

        XCTAssertFalse(habit.isCompleted(on: date))
        XCTAssertTrue(habit.isMinimumCompleted(on: date))
        XCTAssertEqual(habit.currentStreak(reference: date), 1)
    }

    func testSkipPreservesStreakWithoutIncreasingIt() {
        let completedDay = TestFactory.date(day: 2)
        let skippedDay = TestFactory.date(day: 3)
        let habit = TestFactory.habit(createdAt: completedDay)
        TestFactory.entry(.completed, habit: habit, date: completedDay, value: 1)
        TestFactory.entry(.skipped, habit: habit, date: skippedDay)

        XCTAssertEqual(habit.currentStreak(reference: skippedDay), 1)
        let breakdown = habit.currentStreakBreakdown(reference: skippedDay)
        XCTAssertEqual(breakdown.completedDays, 1)
        XCTAssertEqual(breakdown.skippedDays, 1)
    }

    func testUrgeDoesNotBlockRecoveryPrompt() {
        let missedDay = TestFactory.date(day: 2)
        let reference = TestFactory.date(day: 3)
        let habit = TestFactory.habit(direction: .break, createdAt: missedDay)
        TestFactory.entry(.urge, habit: habit, date: missedDay)

        let candidate = habit.recoveryPromptCandidate(before: reference)

        XCTAssertNotNil(candidate)
        XCTAssertTrue(AppCalendar.isSameDay(candidate?.date ?? reference, missedDay))
    }

    func testRecoveryPromptOnlyChecksYesterday() {
        let missedThursday = TestFactory.date(day: 18)
        let reference = TestFactory.date(day: 20)
        let habit = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.thursday],
            targetDaysPerWeek: 1,
            createdAt: missedThursday
        )

        let candidate = habit.recoveryPromptCandidate(before: reference)

        XCTAssertNil(candidate)
    }

    func testRecoveryPromptUsesYesterdayWhenEligible() {
        let yesterday = TestFactory.date(day: 19)
        let reference = TestFactory.date(day: 20)
        let habit = TestFactory.habit(createdAt: yesterday)

        let candidate = habit.recoveryPromptCandidate(before: reference)

        XCTAssertNotNil(candidate)
        XCTAssertTrue(AppCalendar.isSameDay(candidate?.date ?? reference, yesterday))
    }

    func testFlexibleScheduleRecoveryPromptOnlyChecksYesterday() {
        let yesterday = TestFactory.date(day: 19)
        let reference = TestFactory.date(day: 20)
        let habit = TestFactory.habit(
            schedule: .timesPerWeek,
            targetDaysPerWeek: 3,
            createdAt: yesterday
        )

        let candidate = habit.recoveryPromptCandidate(before: reference)

        XCTAssertNotNil(candidate)
        XCTAssertTrue(AppCalendar.isSameDay(candidate?.date ?? reference, yesterday))
    }

    /// La falla que abrió el issue: la hoja preguntaba por un solo hábito por arranque, elegido
    /// por un `.max` que siempre empataba en fecha y terminaba premiando al `createdAt` mayor.
    func testRecoveryPromptCandidatesReturnsEveryYesterdayMiss() {
        let yesterday = TestFactory.date(day: 19)
        let reference = TestFactory.date(day: 20)
        let habits = (0..<3).map { _ in TestFactory.habit(createdAt: yesterday) }

        let candidates = habits.recoveryPromptCandidates(reference: reference)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertTrue(candidates.allSatisfy { AppCalendar.isSameDay($0.date, yesterday) })
    }

    /// El orden es el del receptor, que es el mismo con el que Hoy lista los hábitos: la lista se
    /// lee como un espejo de ayer y no como un ranking por fecha de creación.
    func testRecoveryPromptCandidatesPreserveReceiverOrder() {
        let yesterday = TestFactory.date(day: 19)
        let reference = TestFactory.date(day: 20)
        let first = TestFactory.habit(title: "Leer", createdAt: yesterday)
        let second = TestFactory.habit(title: "Correr", createdAt: yesterday)
        let third = TestFactory.habit(title: "Meditar", createdAt: yesterday)

        let candidates = [first, second, third].recoveryPromptCandidates(reference: reference)

        XCTAssertEqual(candidates.map(\.habit.title), ["Leer", "Correr", "Meditar"])
    }

    /// `isScheduled(on:)` es verdadero todos los días para las agendas flexibles, así que sin
    /// consultar la meta semanal un hábito ya cumplido aparecería en la lista acusando algo que
    /// el usuario sí hizo.
    func testFlexibleHabitThatMetWeeklyTargetIsNotACandidate() {
        let reference = TestFactory.date(day: 20)
        let habit = TestFactory.habit(
            schedule: .timesPerWeek,
            targetDaysPerWeek: 3,
            createdAt: TestFactory.date(day: 16)
        )
        [16, 17, 18].forEach { day in
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: day), value: 1)
        }

        XCTAssertNil(habit.recoveryPromptCandidate(before: reference))
        XCTAssertTrue([habit].recoveryPromptCandidates(reference: reference).isEmpty)
    }
}
