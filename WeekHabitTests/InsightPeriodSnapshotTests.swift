import XCTest
@testable import WeekHabit

/// Snapshot de la tarjeta principal de Insights por periodo (Semana, Mes, Todo).
/// Junio de 2026 empieza en lunes: el 4 es jueves y el 8 es lunes.
@MainActor
final class InsightPeriodSnapshotTests: XCTestCase {

    // MARK: - Semana

    func testWeekOnThursdayLeavesRemainingDaysPendingAndCompares() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(month: 5, day: 1))
        for day in [25, 27, 29] {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(month: 5, day: day), value: 1)
        }
        for day in [1, 2, 4] {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: day), value: 1)
        }

        let snapshot = [habit].insightSnapshot(for: .week, reference: TestFactory.date(day: 4))

        XCTAssertEqual(snapshot.granularity, .day)
        XCTAssertEqual(snapshot.trend.map(\.label), ["L", "M", "X", "J", "V", "S", "D"])
        XCTAssertEqual(snapshot.trend.map(\.isPending), [false, false, false, false, true, true, true])
        XCTAssertEqual(snapshot.trend.firstIndex(where: \.isCurrent), 3)
        XCTAssertEqual(snapshot.current, HabitCompletionStats(completed: 3, scheduled: 4))
        XCTAssertEqual(snapshot.comparison?.baseline, HabitCompletionStats(completed: 3, scheduled: 7))
        XCTAssertEqual(snapshot.range.lowerBound, AppCalendar.startOfDay(for: TestFactory.date(day: 1)))
        XCTAssertEqual(snapshot.range.upperBound, AppCalendar.startOfDay(for: TestFactory.date(day: 7)))
    }

    func testWeekOnMondayHasNoComparisonYet() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(month: 5, day: 1))
        TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 3), value: 1)

        let snapshot = [habit].insightSnapshot(for: .week, reference: TestFactory.date(day: 8))

        XCTAssertNil(snapshot.comparison)
        XCTAssertEqual(snapshot.trend.filter(\.isPending).count, 6)
        XCTAssertEqual(snapshot.current.scheduled, 1)
    }

    func testReviewOfPastWeekHasNoPendingDays() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(month: 5, day: 1))

        let snapshot = [habit].weeklySnapshot(
            weekStart: TestFactory.date(month: 5, day: 25),
            reference: TestFactory.date(day: 4)
        )

        XCTAssertFalse(snapshot.trend.contains(where: \.isPending))
        XCTAssertFalse(snapshot.trend.contains(where: \.isCurrent))
        XCTAssertEqual(snapshot.current.scheduled, 7)
    }

    // MARK: - Mes

    func testMonthKeepsTwelveSlicesWithEdgeLabels() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(month: 4, day: 1))

        let snapshot = [habit].insightSnapshot(for: .month, reference: TestFactory.date(day: 30))

        XCTAssertEqual(snapshot.granularity, .monthSlice)
        XCTAssertEqual(snapshot.trend.count, 12)
        XCTAssertEqual(snapshot.trend.first?.label, "hace 30 días")
        XCTAssertEqual(snapshot.trend.first?.labelAlignment, .leading)
        XCTAssertEqual(snapshot.trend.last?.label, "hoy")
        XCTAssertEqual(snapshot.trend.last?.labelAlignment, .trailing)
        XCTAssertEqual(snapshot.trend.last?.isCurrent, true)
        XCTAssertEqual(snapshot.trend.compactMap(\.label).count, 2)
        XCTAssertEqual(snapshot.range.lowerBound, AppCalendar.startOfDay(for: TestFactory.date(day: 1)))
    }

    // MARK: - Todo

    func testAllWithTwoWeeksUsesWeeklyBarsWithoutComparison() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(day: 8))
        TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 9), value: 1)

        let snapshot = [habit].insightSnapshot(for: .all, reference: TestFactory.date(day: 18))

        XCTAssertEqual(snapshot.granularity, .week)
        XCTAssertEqual(snapshot.trend.count, 2)
        XCTAssertEqual(snapshot.trend.map(\.label), [
            AppFormatters.string(from: TestFactory.date(day: 8), format: "d MMM"),
            AppFormatters.string(from: TestFactory.date(day: 15), format: "d MMM")
        ])
        XCTAssertEqual(snapshot.trend.last?.isCurrent, true)
        XCTAssertNil(snapshot.comparison)
        XCTAssertEqual(snapshot.current, HabitCompletionStats(completed: 1, scheduled: 11))
    }

    func testAllWithFourMonthsLabelsTheFirstWeekOfEachMonth() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(month: 2, day: 2))
        for day in 20...30 {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(month: 5, day: day), value: 1)
        }

        let snapshot = [habit].insightSnapshot(for: .all, reference: TestFactory.date(day: 4))

        XCTAssertEqual(snapshot.granularity, .week)
        XCTAssertEqual(snapshot.trend.count, 18)
        let labels = snapshot.trend.compactMap(\.label)
        XCTAssertEqual(labels.count, 5)
        XCTAssertEqual(labels.last, AppFormatters.lowercased(
            AppFormatters.uppercasedString(from: TestFactory.date(day: 4), format: "MMM")
        ))
        XCTAssertEqual(snapshot.trend.filter(\.isCurrent).count, 1)
        XCTAssertEqual(snapshot.comparison?.baseline.completed, 0)
        XCTAssertEqual(snapshot.comparison?.recent.completed, 11)
        XCTAssertGreaterThan(snapshot.deltaPercentagePoints, 0)
    }

    func testAllWithAYearUsesOneBarPerMonth() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(year: 2025, month: 7, day: 10))

        let snapshot = [habit].insightSnapshot(for: .all, reference: TestFactory.date(day: 10))

        XCTAssertEqual(snapshot.granularity, .month)
        XCTAssertEqual(snapshot.trend.count, 12)
        XCTAssertEqual(snapshot.trend.compactMap(\.label).count, 12)
        XCTAssertEqual(snapshot.trend.last?.isCurrent, true)
        XCTAssertNotNil(snapshot.comparison)
        XCTAssertEqual(
            snapshot.rangeText,
            "desde \(AppFormatters.string(from: TestFactory.date(year: 2025, month: 7, day: 10), format: "MMM yyyy"))"
        )
    }

    func testAllLongerThanEighteenMonthsOnlyLabelsJanuaryWithTheYear() {
        let habit = TestFactory.habit(createdAt: TestFactory.date(year: 2024, month: 10, day: 15))

        let snapshot = [habit].insightSnapshot(for: .all, reference: TestFactory.date(day: 10))

        XCTAssertEqual(snapshot.granularity, .month)
        XCTAssertEqual(snapshot.trend.count, 21)
        XCTAssertEqual(snapshot.trend.compactMap(\.label), ["2025", "2026"])
        XCTAssertFalse(snapshot.trend.contains(where: \.isCurrent))
    }
}
