import XCTest
@testable import WeekHabit

@MainActor
final class InsightMetricsTests: XCTestCase {
    func testReadinessTracksWarmupProvisionalAndStableWindows() {
        let reference = TestFactory.date(day: 30)
        let fresh = makeHabit(createdAt: TestFactory.date(day: 27))
        let provisional = makeHabit(createdAt: TestFactory.date(day: 20))
        let stable = makeHabit(createdAt: TestFactory.date(day: 1))

        let freshReadiness = [fresh].insightReadiness(reference: reference)
        let provisionalReadiness = [provisional].insightReadiness(reference: reference)
        let stableReadiness = [stable].insightReadiness(reference: reference)

        XCTAssertFalse(freshReadiness.isReady)
        XCTAssertEqual(freshReadiness.remainingDays, 2)
        XCTAssertEqual(freshReadiness.progress, 0.6, accuracy: 0.001)
        XCTAssertTrue(provisionalReadiness.isReady)
        XCTAssertTrue(provisionalReadiness.isProvisional)
        XCTAssertFalse(provisionalReadiness.isStable)
        XCTAssertTrue(stableReadiness.isStable)
    }

    func testGlobalSnapshotUsesThirtyDayWindowsTrendBucketsAndMinimumDays() {
        let reference = TestFactory.date(day: 30)
        let habit = makeHabit(createdAt: TestFactory.date(year: 2026, month: 4, day: 1))
        addEntry(.completed, to: habit, on: TestFactory.date(year: 2026, month: 5, day: 31), source: .today)
        addEntry(.completed, to: habit, on: TestFactory.date(day: 1), source: .today)
        addEntry(.minimum, to: habit, on: TestFactory.date(day: 15), source: .today)
        addEntry(.completed, to: habit, on: TestFactory.date(day: 30), source: .focusSession)

        let snapshot = [habit].globalInsightSnapshot(reference: reference)

        XCTAssertEqual(snapshot.current.scheduled, 30)
        XCTAssertEqual(snapshot.current.completed, 2)
        XCTAssertEqual(snapshot.previous.scheduled, 30)
        XCTAssertEqual(snapshot.previous.completed, 1)
        XCTAssertEqual(snapshot.trend.count, 12)
        XCTAssertEqual(snapshot.minimumDays, 1)
        XCTAssertEqual(snapshot.deltaPercentagePoints, 3)
    }

    func testRhythmConfidenceCountsTrustedAndFocusSessionMarks() {
        let reference = TestFactory.date(day: 30)
        let high = makeHabit(createdAt: TestFactory.date(day: 1))
        addEntry(.completed, to: high, on: TestFactory.date(day: 10), source: .today)
        addEntry(.completed, to: high, on: TestFactory.date(day: 11), source: .focusSession)
        addEntry(.completed, to: high, on: TestFactory.date(day: 12), source: .today)
        addEntry(.completed, to: high, on: TestFactory.date(day: 13), source: .manual)

        let learning = makeHabit(createdAt: TestFactory.date(day: 1))
        addEntry(.completed, to: learning, on: TestFactory.date(day: 10), source: .today)
        addEntry(.completed, to: learning, on: TestFactory.date(day: 11), source: .focusSession)
        addEntry(.completed, to: learning, on: TestFactory.date(day: 12), source: .manual)
        addEntry(.completed, to: learning, on: TestFactory.date(day: 13), source: .manual)
        addEntry(.completed, to: learning, on: TestFactory.date(day: 14), source: .manual)

        let low = makeHabit(createdAt: TestFactory.date(day: 1))
        addEntry(.completed, to: low, on: TestFactory.date(day: 10), source: .manual)

        let highConfidence = [high].rhythmConfidence(reference: reference)
        let learningConfidence = [learning].rhythmConfidence(reference: reference)
        let lowConfidence = [low].rhythmConfidence(reference: reference)

        XCTAssertEqual(highConfidence.title, "Alta confianza")
        XCTAssertEqual(highConfidence.trustedMarks, 3)
        XCTAssertEqual(highConfidence.totalMarks, 4)
        XCTAssertEqual(highConfidence.focusSessionMarks, 1)
        XCTAssertEqual(learningConfidence.title, "Aún aprendiendo")
        XCTAssertEqual(lowConfidence.title, "Pocas marcas reales")
    }

    func testAttentionHabitPrioritizesLowerConsistencyAndCarriesFailureType() {
        let reference = TestFactory.date(day: 30)
        let shaky = makeHabit(title: "Shaky", createdAt: TestFactory.date(day: 1))
        let steadier = makeHabit(title: "Steadier", createdAt: TestFactory.date(day: 1))

        for day in [1, 2, 3, 4, 5] {
            addEntry(.completed, to: steadier, on: TestFactory.date(day: day), source: .today)
        }
        addEntry(.missed, to: shaky, on: TestFactory.date(day: 10), source: .today, reason: .badTiming)
        addEntry(.missed, to: shaky, on: TestFactory.date(day: 11), source: .today, reason: .badTiming)

        let attention = [steadier, shaky].attentionHabit(reference: reference)

        XCTAssertEqual(attention?.habit.id, shaky.id)
        XCTAssertEqual(attention?.failureType?.title, "Mal horario")
        XCTAssertEqual(attention?.recommendation, "El horario parece estar estorbando; probemos una ventana más realista.")
    }

    func testUrgePeakHourRequiresMinimumCountAndReturnsPeakContext() {
        let reference = TestFactory.date(day: 30)
        let breakHabit = makeHabit(
            title: "No scrolling",
            createdAt: TestFactory.date(day: 1),
            direction: .break
        )
        addEntry(.urge, to: breakHabit, on: TestFactory.date(day: 10, hour: 18), source: .today)
        addEntry(.urge, to: breakHabit, on: TestFactory.date(day: 11, hour: 18), source: .today)

        XCTAssertNil([breakHabit].urgePeakHourInsight(reference: reference))

        addEntry(.urge, to: breakHabit, on: TestFactory.date(day: 12, hour: 18), source: .today)
        let insight = [breakHabit].urgePeakHourInsight(reference: reference)

        XCTAssertEqual(insight?.window.startHour, 18)
        XCTAssertEqual(insight?.totalCount, 3)
        XCTAssertEqual(insight?.habits.first?.habit.id, breakHabit.id)
    }

    @discardableResult
    private func addEntry(
        _ kind: EntryKind,
        to habit: Habit,
        on date: Date,
        source: HabitEntrySource,
        reason: HabitFailureReason? = nil
    ) -> HabitEntry {
        let entry = HabitEntry(
            date: date,
            completedAt: date,
            source: source,
            kind: kind,
            failureReason: reason,
            habit: habit
        )
        habit.entries.append(entry)
        return entry
    }

    private func makeHabit(
        title: String = "Habit",
        createdAt: Date,
        direction: HabitDirection = .build
    ) -> Habit {
        Habit(
            title: title,
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            scheduleKind: .daily,
            direction: direction,
            createdAt: createdAt
        )
    }
}
