import XCTest
@testable import WeekHabit

@MainActor
final class ExperimentSuggestionTests: XCTestCase {
    func testSuggestionsAreEmptyWithoutEnoughReadinessOrCompletionData() {
        let reference = TestFactory.date(day: 30)
        let fresh = makeHabit(createdAt: TestFactory.date(day: 27))
        let noMarks = makeHabit(createdAt: TestFactory.date(day: 1))

        XCTAssertTrue([fresh].rhythmExperimentSuggestions(reference: reference).isEmpty)
        XCTAssertTrue([noMarks].rhythmExperimentSuggestions(reference: reference).isEmpty)
    }

    func testSuggestionsExcludeHabitsWithActiveExperiment() {
        let reference = TestFactory.date(day: 30)
        let habit = makeHabit(createdAt: TestFactory.date(day: 1))
        addEntries(to: habit, days: 1...10, hour: 8)

        let suggestions = [habit].rhythmExperimentSuggestions(
            reference: reference,
            excludingHabitIDs: [habit.id]
        )

        XCTAssertTrue(suggestions.isEmpty)
    }

    func testLowConsistencySuggestionReducesTargetDaysAndKeepsStrongDays() {
        let reference = TestFactory.date(day: 30)
        let habit = makeHabit(
            createdAt: TestFactory.date(day: 1),
            targetDaysPerWeek: 5,
            activeDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            schedule: .specificDays
        )
        for day in [1, 2, 3, 4, 5] {
            addEntry(to: habit, on: TestFactory.date(day: day), hour: 7)
        }

        let suggestion = [habit].rhythmExperimentSuggestion(reference: reference)

        XCTAssertEqual(suggestion?.title, "Prueba bajar la fricción")
        XCTAssertEqual(suggestion?.targetDaysPerWeek, 4)
        XCTAssertEqual(suggestion?.baselineConsistency ?? 0, 5.0 / 22.0, accuracy: 0.001)
        XCTAssertFalse(suggestion?.activeDays.isEmpty ?? true)
    }

    func testReliableHourSignalProducesFixedHourSuggestion() {
        let reference = TestFactory.date(day: 30)
        let habit = makeHabit(createdAt: TestFactory.date(day: 1))
        addEntries(to: habit, days: 1...20, hour: 8)

        let suggestion = [habit].rhythmExperimentSuggestion(reference: reference)

        XCTAssertEqual(suggestion?.title, "Prueba una hora fija")
        XCTAssertEqual(suggestion?.targetDaysPerWeek, 7)
        XCTAssertEqual(suggestion?.suggestedStartHour, 8)
        XCTAssertEqual(suggestion?.hourText, "8:00 – 9:00")
    }

    func testSuggestionsSortHigherPriorityBeforeLowerPriority() {
        let reference = TestFactory.date(day: 30)
        let lowConsistency = makeHabit(
            title: "Low",
            createdAt: TestFactory.date(day: 1),
            targetDaysPerWeek: 5,
            activeDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            schedule: .specificDays
        )
        let steady = makeHabit(title: "Steady", createdAt: TestFactory.date(day: 1))

        for day in [1, 2, 3, 4, 5] {
            addEntry(to: lowConsistency, on: TestFactory.date(day: day), hour: 7)
        }
        addEntries(to: steady, days: 1...22, hour: 8)

        let suggestions = [steady, lowConsistency].rhythmExperimentSuggestions(reference: reference)

        XCTAssertEqual(suggestions.map { $0.suggestion.habit.id }.first, lowConsistency.id)
        XCTAssertGreaterThanOrEqual(
            suggestions.first?.priorityScore ?? 0,
            suggestions.dropFirst().first?.priorityScore ?? 0
        )
    }

    @discardableResult
    private func addEntry(
        to habit: Habit,
        on date: Date,
        hour: Int,
        source: HabitEntrySource = .today,
        reason: HabitFailureReason? = nil
    ) -> HabitEntry {
        let completedAt = AppCalendar.current.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: date
        ) ?? date
        let entry = HabitEntry(
            date: date,
            completedAt: completedAt,
            source: source,
            kind: .completed,
            failureReason: reason,
            habit: habit
        )
        habit.entries.append(entry)
        return entry
    }

    private func addEntries(
        to habit: Habit,
        days: ClosedRange<Int>,
        hour: Int
    ) {
        for day in days {
            addEntry(to: habit, on: TestFactory.date(day: day), hour: hour)
        }
    }

    private func makeHabit(
        title: String = "Habit",
        createdAt: Date,
        targetDaysPerWeek: Int = 7,
        activeDays: Set<Weekday>? = nil,
        schedule: HabitScheduleKind = .daily
    ) -> Habit {
        Habit(
            title: title,
            targetDaysPerWeek: targetDaysPerWeek,
            activeDaysOfWeek: activeDays ?? Set(Weekday.ordered),
            scheduleKind: schedule,
            createdAt: createdAt
        )
    }
}
