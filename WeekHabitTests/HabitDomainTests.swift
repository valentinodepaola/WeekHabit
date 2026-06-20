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
        XCTAssertFalse(candidate?.isWeeklyFlexibleMiss ?? true)
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
        XCTAssertFalse(candidate?.isWeeklyFlexibleMiss ?? true)
    }
}
