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

    /// La compuerta es por día natural, no por sesión: si el usuario ya cerró la hoja hoy, no
    /// vuelve a aparecer sola aunque relance la app. La bandera de sesión anterior vivía en el
    /// `@State` de la vista, que `TabView` conserva, así que solo se recreaba en un arranque en frío.
    func testRecoveryPromptIsNotAutoPresentedTwiceTheSameDay() {
        let model = TodayScreenModel()
        let today = TestFactory.date(day: 20)

        XCTAssertTrue(
            model.presentRecoveryPromptIfNeeded(
                lastAutoPresentedDay: nil,
                reference: today,
                hasCandidates: true
            )
        )
        XCTAssertEqual(model.sheetRoute?.id, expectedRouteID(for: today))

        model.sheetRoute = nil
        XCTAssertFalse(
            model.presentRecoveryPromptIfNeeded(
                lastAutoPresentedDay: TestFactory.date(day: 20, hour: 8),
                reference: today,
                hasCandidates: true
            )
        )
        XCTAssertNil(model.sheetRoute)
    }

    func testRecoveryPromptIsAutoPresentedAgainTheNextDay() {
        let model = TodayScreenModel()
        let tomorrow = TestFactory.date(day: 21)

        XCTAssertTrue(
            model.presentRecoveryPromptIfNeeded(
                lastAutoPresentedDay: TestFactory.date(day: 20),
                reference: tomorrow,
                hasCandidates: true
            )
        )
        XCTAssertEqual(model.sheetRoute?.id, expectedRouteID(for: tomorrow))
    }

    func testRecoveryPromptIsSkippedWithoutCandidates() {
        let model = TodayScreenModel()

        XCTAssertFalse(
            model.presentRecoveryPromptIfNeeded(
                lastAutoPresentedDay: nil,
                reference: TestFactory.date(day: 20),
                hasCandidates: false
            )
        )
        XCTAssertNil(model.sheetRoute)
    }

    func testRecoveryPromptIsSkippedWhenSomethingIsAlreadyPresented() {
        let model = TodayScreenModel()
        model.coverRoute = .plan(.create)

        XCTAssertFalse(
            model.presentRecoveryPromptIfNeeded(
                lastAutoPresentedDay: nil,
                reference: TestFactory.date(day: 20),
                hasCandidates: true
            )
        )

        XCTAssertNil(model.sheetRoute)
    }

    /// La ruta lleva la fecha y nada más: si su `id` dependiera de los candidatos, cambiaría al
    /// contestar uno y SwiftUI reconstruiría la hoja a media navegación.
    private func expectedRouteID(for reference: Date) -> String {
        let day = AppCalendar.startOfDay(for: reference)
        return "recoveryPrompt-\(day.timeIntervalSinceReferenceDate)"
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
        model.presentRecoveryPromptIfNeeded(
            lastAutoPresentedDay: nil,
            reference: TestFactory.date(day: 20),
            hasCandidates: true
        )
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
