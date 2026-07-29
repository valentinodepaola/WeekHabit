import XCTest
@testable import WeekHabit

/// La secuencia hito → nota era, dentro de `TodayView`, un reintento temporizado que
/// consultaba `sheetRoute` hasta seis veces y descartaba la nota en silencio si no lograba
/// presentarla. Al mover el estado a `TodayScreenModel` quedó testeable, que es la mitad del
/// argumento de la Fase 3.
@MainActor
final class TodayScreenModelTests: XCTestCase {

    private func makeEntry() -> HabitEntry {
        let habit = TestFactory.habit()
        return TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 1), value: 1)
    }

    /// Espera a que se cumpla una condición que llega por `DispatchQueue.main.asyncAfter`.
    private func wait(
        upTo timeout: TimeInterval = 2,
        for condition: @escaping () -> Bool
    ) {
        let expectation = expectation(description: "condición cumplida")
        var timer: Timer?
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            if condition() {
                timer?.invalidate()
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: timeout)
        timer?.invalidate()
    }

    // MARK: - Nota sin hito

    func testNoteIsPresentedImmediatelyWhenNothingElseIsOnScreen() {
        let model = TodayScreenModel()
        let entry = makeEntry()

        model.requestNoteEntry(entry)

        XCTAssertEqual(model.sheetRoute?.id, "noteEntry-\(entry.id)")
    }

    func testNoteIsQueuedInsteadOfReplacingAVisibleSheet() {
        let model = TodayScreenModel()
        model.sheetRoute = .createMenu

        model.requestNoteEntry(makeEntry())

        // Pisar el `item` de un sheet presentado deja la presentación en un estado
        // inconsistente: la nota tiene que esperar.
        XCTAssertEqual(model.sheetRoute?.id, "createMenu")
    }

    func testQueuedNoteIsPresentedOnceTheSheetIsDismissed() {
        let model = TodayScreenModel()
        let entry = makeEntry()
        model.sheetRoute = .createMenu
        model.requestNoteEntry(entry)

        model.sheetRoute = nil
        model.presentPendingNoteIfPossible()

        wait { model.sheetRoute != nil }
        XCTAssertEqual(model.sheetRoute?.id, "noteEntry-\(entry.id)")
    }

    // MARK: - Nota diferida por un hito

    func testMilestoneIsPresentedAndTheNoteWaitsBehindIt() {
        let model = TodayScreenModel()
        let entry = makeEntry()
        let payload = MilestoneCelebrationPayload(habit: TestFactory.habit(), milestone: .week)

        model.presentMilestone(payload, noteEntry: entry, after: 0.05)

        wait { model.milestoneCover != nil }
        XCTAssertEqual(model.milestoneCover?.id, payload.id)
        XCTAssertNil(model.sheetRoute, "la nota no puede aparecer debajo de la celebración")
    }

    func testNoteIsPresentedAfterTheMilestoneIsDismissed() {
        let model = TodayScreenModel()
        let entry = makeEntry()
        let payload = MilestoneCelebrationPayload(habit: TestFactory.habit(), milestone: .week)

        model.presentMilestone(payload, noteEntry: entry, after: 0.05)
        wait { model.milestoneCover != nil }

        // Lo que hace el `onDismiss` del fullScreenCover.
        model.milestoneCover = nil
        model.presentPendingNoteIfPossible()

        wait { model.sheetRoute != nil }
        XCTAssertEqual(model.sheetRoute?.id, "noteEntry-\(entry.id)")
    }

    func testPendingNoteStaysQueuedWhileTheMilestoneIsStillVisible() {
        let model = TodayScreenModel()
        let entry = makeEntry()
        let payload = MilestoneCelebrationPayload(habit: TestFactory.habit(), milestone: .week)

        model.presentMilestone(payload, noteEntry: entry, after: 0.05)
        wait { model.milestoneCover != nil }

        model.presentPendingNoteIfPossible()

        // Sin descartar la celebración, la nota sigue esperando y no se pierde.
        XCTAssertNil(model.sheetRoute)
        model.milestoneCover = nil
        model.presentPendingNoteIfPossible()
        wait { model.sheetRoute != nil }
        XCTAssertEqual(model.sheetRoute?.id, "noteEntry-\(entry.id)")
    }

    func testMilestoneWithoutNoteLeavesNothingQueued() {
        let model = TodayScreenModel()
        let payload = MilestoneCelebrationPayload(habit: TestFactory.habit(), milestone: .week)

        model.presentMilestone(payload, noteEntry: nil, after: 0.05)
        wait { model.milestoneCover != nil }
        model.milestoneCover = nil
        model.presentPendingNoteIfPossible()

        let settled = expectation(description: "sin nota pendiente")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
        XCTAssertNil(model.sheetRoute)
    }

    // MARK: - Confirmaciones de borrado

    func testDeletionConfirmationFlagsDeriveFromTheirOptional() {
        let model = TodayScreenModel()
        let habit = TestFactory.habit()

        XCTAssertFalse(model.isConfirmingHabitDeletion)
        model.requestHabitDeletion(habit)
        XCTAssertTrue(model.isConfirmingHabitDeletion)

        // Cancelar la alerta limpia el opcional: antes eran dos estados que podían
        // desincronizarse y dejar la alerta pidiendo borrar un hábito ya descartado.
        model.isConfirmingHabitDeletion = false
        XCTAssertNil(model.habitToDelete)
    }

    // MARK: - Prompt de recuperación

    func testRecoveryPromptIsShownOnlyOncePerSession() {
        let model = TodayScreenModel()
        let habit = TestFactory.habit()
        let candidate = RecoveryPromptCandidate(
            habit: habit,
            date: TestFactory.date(day: 1),
            isWeeklyFlexibleMiss: false
        )

        model.presentRecoveryPromptIfNeeded(candidate: candidate)
        XCTAssertNotNil(model.sheetRoute)

        model.sheetRoute = nil
        model.presentRecoveryPromptIfNeeded(candidate: candidate)
        XCTAssertNil(model.sheetRoute)
    }

    func testRecoveryPromptIsSkippedWhenSomethingIsAlreadyPresented() {
        let model = TodayScreenModel()
        let habit = TestFactory.habit()
        let candidate = RecoveryPromptCandidate(
            habit: habit,
            date: TestFactory.date(day: 1),
            isWeeklyFlexibleMiss: false
        )
        model.coverRoute = .plan(.create)

        model.presentRecoveryPromptIfNeeded(candidate: candidate)

        XCTAssertNil(model.sheetRoute)
    }
}
