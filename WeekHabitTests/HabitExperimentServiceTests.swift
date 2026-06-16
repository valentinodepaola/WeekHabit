import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class HabitExperimentServiceTests: XCTestCase {
    func testStartPersistsExperimentAndAppliesSuggestionToHabit() throws {
        let store = try TestStore()
        let habit = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday, .wednesday, .friday],
            targetDaysPerWeek: 3
        )
        store.insert(habit)

        let reference = TestFactory.date(day: 8)
        let suggestion = makeSuggestion(
            habit: habit,
            targetDaysPerWeek: 2,
            activeDays: [.tuesday, .thursday]
        )

        let experiment = try HabitExperimentService.start(
            suggestion: suggestion,
            existingExperiments: [],
            reference: reference,
            modelContext: store.context
        )

        let experiments = try store.context.fetch(FetchDescriptor<HabitExperiment>())
        XCTAssertEqual(experiments.map(\.id), [experiment?.id])
        XCTAssertEqual(habit.targetDaysPerWeek, 2)
        XCTAssertEqual(habit.activeDaysOfWeek, [.tuesday, .thursday])
        XCTAssertEqual(habit.scheduleKind, .specificDays)
        XCTAssertEqual(experiment?.originalTargetDaysPerWeek, 3)
        XCTAssertEqual(experiment?.originalActiveDaysOfWeek, [.monday, .wednesday, .friday])
        XCTAssertEqual(experiment?.experimentTargetDaysPerWeek, 2)
        XCTAssertEqual(experiment?.experimentActiveDaysOfWeek, [.tuesday, .thursday])
        XCTAssertEqual(experiment?.suggestedStartHour, 9)
        XCTAssertEqual(experiment?.baselineConsistency, 0.42)
        XCTAssertEqual(experiment?.startedAt, AppCalendar.startOfDay(for: reference))
    }

    func testStartSkipsWhenHabitAlreadyHasActiveExperiment() throws {
        let store = try TestStore()
        let habit = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday, .wednesday, .friday],
            targetDaysPerWeek: 3
        )
        store.insert(habit)

        let reference = TestFactory.date(day: 8)
        let existingExperiment = HabitExperiment(
            habit: habit,
            experimentTargetDaysPerWeek: 2,
            experimentActiveDaysOfWeek: [.monday, .friday],
            suggestedStartHour: nil,
            baselineConsistency: 0.5,
            startedAt: reference
        )
        store.context.insert(existingExperiment)
        try store.save()

        let suggestion = makeSuggestion(
            habit: habit,
            targetDaysPerWeek: 1,
            activeDays: [.tuesday]
        )

        let experiment = try HabitExperimentService.start(
            suggestion: suggestion,
            existingExperiments: [existingExperiment],
            reference: reference,
            modelContext: store.context
        )

        let experiments = try store.context.fetch(FetchDescriptor<HabitExperiment>())
        XCTAssertNil(experiment)
        XCTAssertEqual(experiments.map(\.id), [existingExperiment.id])
        XCTAssertEqual(habit.targetDaysPerWeek, 3)
        XCTAssertEqual(habit.activeDaysOfWeek, [.monday, .wednesday, .friday])
    }

    private func makeSuggestion(
        habit: Habit,
        targetDaysPerWeek: Int,
        activeDays: Set<Weekday>
    ) -> RhythmExperimentSuggestion {
        RhythmExperimentSuggestion(
            habit: habit,
            title: "Test suggestion",
            message: "Try a smaller rhythm.",
            reason: "This is easier to keep.",
            targetDaysPerWeek: targetDaysPerWeek,
            activeDays: activeDays,
            suggestedStartHour: 9,
            baselineConsistency: 0.42
        )
    }
}
