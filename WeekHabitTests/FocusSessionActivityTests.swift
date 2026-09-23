import XCTest
@testable import WeekHabit

/// La Live Activity dibuja solo lo que le llega en sus atributos: las vistas viven en la
/// extensión, fuera del alcance de este target. Por eso se prueba lo que la arma —las fechas de
/// la sesión y el copy compartido— y el arreglo de `endedAt` que la vuelve necesaria.
@MainActor
final class FocusSessionActivityTests: XCTestCase {

    private func session(
        habitCount: Int = 2,
        durationSeconds: Int? = 1500,
        startedAt: Date? = nil
    ) -> FocusSession {
        FocusSession(
            selectedHabitIDs: Set((0..<habitCount).map { _ in UUID() }),
            durationSeconds: durationSeconds,
            startedAt: startedAt ?? TestFactory.date(day: 3, hour: 10)
        )
    }

    // MARK: - Hora de fin

    func testScheduledEndDateAddsTheDuration() {
        let start = TestFactory.date(day: 3, hour: 10)
        let timed = session(durationSeconds: 1500, startedAt: start)

        XCTAssertEqual(timed.scheduledEndDate, start.addingTimeInterval(1500))
    }

    func testOpenSessionHasNoScheduledEnd() {
        XCTAssertNil(session(durationSeconds: nil).scheduledEndDate)
    }

    // MARK: - Referencia de revisión

    func testReviewReferenceIsTheScheduledEndWhenTheAppReturnsLate() {
        let start = TestFactory.date(day: 3, hour: 10)
        let timed = session(durationSeconds: 600, startedAt: start)
        let returnedAt = start.addingTimeInterval(3600)

        XCTAssertEqual(timed.reviewReference(observedAt: returnedAt), start.addingTimeInterval(600))
    }

    func testReviewReferenceIsTheObservedTimeWhenFinishedEarly() {
        let start = TestFactory.date(day: 3, hour: 10)
        let timed = session(durationSeconds: 1500, startedAt: start)
        let finishedAt = start.addingTimeInterval(300)

        XCTAssertEqual(timed.reviewReference(observedAt: finishedAt), finishedAt)
    }

    func testReviewReferenceOfAnOpenSessionIsTheObservedTime() {
        let start = TestFactory.date(day: 3, hour: 10)
        let open = session(durationSeconds: nil, startedAt: start)
        let finishedAt = start.addingTimeInterval(5000)

        XCTAssertEqual(open.reviewReference(observedAt: finishedAt), finishedAt)
    }

    // MARK: - Contenido de la actividad

    func testContentStateCarriesTheSessionDates() {
        let start = TestFactory.date(day: 3, hour: 10)
        let state = FocusSessionActivityAttributes.ContentState(
            session: session(durationSeconds: 600, startedAt: start)
        )

        XCTAssertEqual(state.startDate, start)
        XCTAssertEqual(state.endDate, start.addingTimeInterval(600))
    }

    func testContentStateOfAnOpenSessionHasNoEnd() {
        let state = FocusSessionActivityAttributes.ContentState(session: session(durationSeconds: nil))
        XCTAssertNil(state.endDate)
    }

    func testAttributesCountTheSelectedHabits() {
        let focus = session(habitCount: 3)
        let attributes = FocusSessionActivityAttributes(session: focus, isSequenced: true)

        XCTAssertEqual(attributes.sessionID, focus.id)
        XCTAssertEqual(attributes.habitCount, 3)
        XCTAssertEqual(attributes.subtitle, "3 hábitos en secuencia")
    }

    // MARK: - Copy

    func testSubtitleNamesFocusAndSequence() {
        XCTAssertEqual(FocusSessionCopy.focusSubtitle(habitCount: 1, isSequenced: false), "1 hábito en enfoque")
        XCTAssertEqual(FocusSessionCopy.focusSubtitle(habitCount: 4, isSequenced: false), "4 hábitos en enfoque")
        XCTAssertEqual(FocusSessionCopy.focusSubtitle(habitCount: 4, isSequenced: true), "4 hábitos en secuencia")
    }

    func testSequenceOfOneHabitReadsAsFocus() {
        // Una secuencia de un solo hábito no es una secuencia.
        XCTAssertEqual(FocusSessionCopy.focusSubtitle(habitCount: 1, isSequenced: true), "1 hábito en enfoque")
    }
}
