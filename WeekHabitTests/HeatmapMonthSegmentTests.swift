import XCTest
@testable import WeekHabit

/// `HeatmapMonthSegment.segments(forWeekStarts:)` la comparten el heatmap anual de la app y el
/// widget "Año de constancia": si agrupara distinto, los dos dejarían de leerse como el mismo
/// objeto.
@MainActor
final class HeatmapMonthSegmentTests: XCTestCase {

    /// `count` lunes consecutivos a partir del 2026-06-01.
    private func weekStarts(count: Int, fromDay day: Int = 1) -> [Date] {
        let calendar = AppCalendar.current
        let first = TestFactory.date(day: day)
        return (0..<count).map { calendar.date(byAdding: .weekOfYear, value: $0, to: first) ?? first }
    }

    func testEmptyInputProducesNoSegments() {
        XCTAssertTrue(HeatmapMonthSegment.segments(forWeekStarts: []).isEmpty)
    }

    func testEveryWeekLandsInExactlyOneSegmentInOrder() {
        let segments = HeatmapMonthSegment.segments(forWeekStarts: weekStarts(count: 16))

        XCTAssertEqual(segments.flatMap(\.weekIndices), Array(0..<16))
    }

    func testConsecutiveSegmentsAreDistinctMonths() {
        let segments = HeatmapMonthSegment.segments(forWeekStarts: weekStarts(count: 24))
        let ids = segments.map(\.id)

        XCTAssertEqual(Set(ids).count, ids.count, "ningún mes aparece en dos tramos")
        XCTAssertGreaterThanOrEqual(segments.count, 5, "24 semanas tocan al menos 5 meses")
    }

    func testWeekBelongsToTheMonthOfItsThursday() {
        // Lunes 2026-06-29; su jueves es el 2026-07-02, así que la semana es de julio.
        let june29 = TestFactory.date(day: 29)
        let segments = HeatmapMonthSegment.segments(forWeekStarts: [june29])

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.id, "2026-7")
        XCTAssertEqual(
            segments.first?.label,
            AppFormatters.uppercasedString(from: TestFactory.date(year: 2026, month: 7, day: 2), format: "MMM")
        )
    }

    func testLabelIsUppercaseAndDelegatesToTheSharedFormatter() {
        let segment = try? XCTUnwrap(HeatmapMonthSegment.segments(forWeekStarts: weekStarts(count: 1)).first)
        let label = segment?.label ?? ""

        XCTAssertFalse(label.isEmpty)
        XCTAssertEqual(label, label.uppercased(with: Locale(identifier: "es_MX")))
        XCTAssertEqual(
            label,
            AppFormatters.uppercasedString(from: TestFactory.date(day: 4), format: "MMM")
        )
    }
}
