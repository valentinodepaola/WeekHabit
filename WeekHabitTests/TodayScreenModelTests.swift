import XCTest
@testable import WeekHabit

/// Las reglas de quién puede ocupar la pantalla de Hoy vivían dentro de `TodayView` y no se
/// podían probar. Al mover el estado a `TodayScreenModel` quedaron testeables, que es la mitad
/// del argumento de la Fase 3.
@MainActor
final class TodayScreenModelTests: XCTestCase {

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

    // MARK: - Celebración de hito

    func testMilestoneIsPresentedAfterItsDelay() {
        let model = TodayScreenModel()
        let payload = MilestoneCelebrationPayload(habit: TestFactory.habit(), milestone: .week)

        model.presentMilestone(payload, after: 0.05)
        XCTAssertNil(model.milestoneCover, "el hito espera a que termine la animación de la lista")

        wait { model.milestoneCover != nil }
        XCTAssertEqual(model.milestoneCover?.milestone, .week)
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

    // MARK: - Ayuda

    func testHelpIsPresentedWhenTheScreenIsFree() {
        let model = TodayScreenModel()

        XCTAssertTrue(model.presentHelpIfPossible())
        XCTAssertEqual(model.sheetRoute?.id, "help")
    }

    /// La regla de precedencia: el prompt de recuperación habla de ayer y su ventana se cierra;
    /// la ayuda es perenne y puede esperar al próximo arranque.
    func testHelpCedesItsTurnToTheRecoveryPrompt() {
        let model = TodayScreenModel()
        let candidate = RecoveryPromptCandidate(
            habit: TestFactory.habit(),
            date: TestFactory.date(day: 1),
            isWeeklyFlexibleMiss: false
        )
        model.presentRecoveryPromptIfNeeded(candidate: candidate)
        let presentedRoute = model.sheetRoute?.id

        XCTAssertFalse(model.presentHelpIfPossible())
        XCTAssertEqual(model.sheetRoute?.id, presentedRoute, "la ayuda no puede pisar la hoja presentada")
    }

    func testHelpIsSkippedWhileACoverIsPresented() {
        let model = TodayScreenModel()
        model.coverRoute = .plan(.create)

        XCTAssertFalse(model.presentHelpIfPossible())
        XCTAssertNil(model.sheetRoute)
    }

    func testHelpIsSkippedWhileAMilestoneIsStillVisible() {
        let model = TodayScreenModel()
        let payload = MilestoneCelebrationPayload(habit: TestFactory.habit(), milestone: .week)
        model.presentMilestone(payload, after: 0.05)
        wait { model.milestoneCover != nil }

        XCTAssertFalse(model.presentHelpIfPossible())
        XCTAssertNil(model.sheetRoute)
    }
}
