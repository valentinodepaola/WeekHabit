import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class WeeklyReviewEditorServiceTests: XCTestCase {
    func testSaveDoesNotCreateDuplicateForExistingWeek() throws {
        let store = try TestStore()
        let weekStart = TestFactory.date(day: 1)
        let existingReview = WeeklyReview(weekStart: weekStart)
        store.context.insert(existingReview)
        try store.save()

        let result = try WeeklyReviewEditorService.save(
            input: input(weekStart: weekStart),
            habits: [],
            existingReviews: [existingReview],
            reference: TestFactory.date(day: 8),
            modelContext: store.context
        )

        let reviews = try store.context.fetch(FetchDescriptor<WeeklyReview>())
        XCTAssertFalse(result.didCreateReview)
        XCTAssertEqual(reviews.count, 1)
    }

    func testSavePersistsDecisionPerHabit() throws {
        let store = try TestStore()
        let weekStart = TestFactory.date(day: 1)
        let habitA = TestFactory.habit(createdAt: weekStart)
        let habitB = TestFactory.habit(createdAt: weekStart)
        store.insert(habitA)
        store.insert(habitB)

        _ = try WeeklyReviewEditorService.save(
            input: input(
                weekStart: weekStart,
                decisions: [
                    habitA.id: .keep,
                    habitB.id: .adjust
                ]
            ),
            habits: [habitA, habitB],
            existingReviews: [],
            reference: TestFactory.date(day: 8),
            modelContext: store.context
        )

        let decisions = try store.context.fetch(FetchDescriptor<WeeklyReviewDecision>())
        XCTAssertEqual(decisions.count, 2)
        XCTAssertEqual(Set(decisions.map(\.habitID)), Set([habitA.id, habitB.id]))
        XCTAssertEqual(decisions.first { $0.habitID == habitA.id }?.decision, .keep)
        XCTAssertEqual(decisions.first { $0.habitID == habitB.id }?.decision, .adjust)
    }

    func testSaveCalculatesWeeklyCompletionRatios() throws {
        let store = try TestStore()
        let weekStart = TestFactory.date(day: 1)
        let habit = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday, .tuesday],
            targetDaysPerWeek: 2,
            createdAt: weekStart
        )
        store.insert(habit)
        TestFactory.entry(.completed, habit: habit, date: weekStart, value: 1)

        _ = try WeeklyReviewEditorService.save(
            input: input(weekStart: weekStart, decisions: [habit.id: .keep]),
            habits: [habit],
            existingReviews: [],
            reference: TestFactory.date(day: 8),
            modelContext: store.context
        )

        let decisions = try store.context.fetch(FetchDescriptor<WeeklyReviewDecision>())
        XCTAssertEqual(decisions.first?.weeklyCompletionRatio ?? -1, 0.5, accuracy: 0.001)
    }

    func testSavePausesOnlyPauseDecisions() throws {
        let store = try TestStore()
        let weekStart = TestFactory.date(day: 1)
        let reference = TestFactory.date(day: 8, hour: 18)
        let keepHabit = TestFactory.habit(createdAt: weekStart)
        let pauseHabit = TestFactory.habit(createdAt: weekStart)
        store.insert(keepHabit)
        store.insert(pauseHabit)

        let result = try WeeklyReviewEditorService.save(
            input: input(
                weekStart: weekStart,
                decisions: [
                    keepHabit.id: .keep,
                    pauseHabit.id: .pause
                ]
            ),
            habits: [keepHabit, pauseHabit],
            existingReviews: [],
            reference: reference,
            modelContext: store.context
        )

        let expectedPauseEnd = AppCalendar.current.date(
            byAdding: .day,
            value: 7,
            to: AppCalendar.startOfDay(for: reference)
        )
        XCTAssertNil(keepHabit.pausedUntil)
        XCTAssertEqual(pauseHabit.pausedUntil, expectedPauseEnd)
        XCTAssertEqual(result.pausedHabitIDs, [pauseHabit.id])
    }

    func testSaveNormalizesBlankReflectionNoteToNil() throws {
        let store = try TestStore()
        let weekStart = TestFactory.date(day: 1)

        let result = try WeeklyReviewEditorService.save(
            input: input(weekStart: weekStart, note: "   \n "),
            habits: [],
            existingReviews: [],
            reference: TestFactory.date(day: 8),
            modelContext: store.context
        )

        XCTAssertNil(result.review?.reflectionNote)
    }

    private func input(
        weekStart: Date,
        note: String = "  Good week  ",
        decisions: [UUID: WeeklyReviewDecisionKind] = [:]
    ) -> WeeklyReviewInput {
        WeeklyReviewInput(
            weekStart: weekStart,
            weekEnd: AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart,
            reflectionNote: note,
            decisions: decisions
        )
    }
}
