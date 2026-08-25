//
//  TodayScreenModel.swift
//  WeekHabit
//

import Foundation
import Observation

/// Estado de presentación y navegación de `TodayView`.
///
/// Reemplaza los 13 `@State` sueltos que la vista sostenía, con sus reglas implícitas entre
/// sí. No guarda datos del dominio ni escribe en el `ModelContext`: las mutaciones siguen en
/// la vista, delegadas a los servicios.
@Observable
final class TodayScreenModel {

    // MARK: - Rutas

    var coverRoute: TodayCoverRoute?
    var sheetRoute: TodaySheetRoute?
    var milestoneCover: MilestoneCelebrationPayload?
    var selectedHabit: Habit?
    var detailPlan: Plan?

    // MARK: - Confirmaciones y errores

    var habitToDelete: Habit?
    var planToDelete: Plan?
    var failure: TodayFailure?

    // MARK: - Estado de sección

    var expandedPlans: Set<UUID> = []
    var latestFreezeExplainerMessage: String?
    private(set) var didShowRecoveryPromptThisSession = false

    // MARK: - Confirmaciones como binding

    /// Las alertas de borrado se derivan del opcional en vez de llevar un `Bool` aparte:
    /// eran dos estados para una sola condición, y podían desincronizarse.
    var isConfirmingHabitDeletion: Bool {
        get { habitToDelete != nil }
        set { if !newValue { habitToDelete = nil } }
    }

    var isConfirmingPlanDeletion: Bool {
        get { planToDelete != nil }
        set { if !newValue { planToDelete = nil } }
    }

    // MARK: - Presentaciones

    func requestHabitDeletion(_ habit: Habit) {
        habitToDelete = habit
    }

    func requestPlanDeletion(_ plan: Plan) {
        planToDelete = plan
    }

    /// Abre la ayuda sólo si la pantalla está libre. Devuelve si llegó a presentarla, para que la
    /// vista marque el flag de "ya la vio" únicamente cuando el usuario de verdad la vio: si el
    /// prompt de recuperación ganó el turno, la ayuda espera al próximo arranque en vez de gastarse.
    @discardableResult
    func presentHelpIfPossible() -> Bool {
        guard sheetRoute == nil, coverRoute == nil, milestoneCover == nil else { return false }
        sheetRoute = .help
        return true
    }

    /// Cierra la hoja actual y abre la siguiente cuando terminó de desaparecer. El retardo es
    /// deliberado: presentar dos hojas encimadas en el mismo ciclo las pisa.
    func replaceSheet(after delay: TimeInterval = 0.25, with next: @escaping () -> Void) {
        sheetRoute = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            next()
        }
    }

    /// Muestra la celebración del hito tras el retardo que deja terminar la animación de la lista.
    func presentMilestone(
        _ payload: MilestoneCelebrationPayload,
        after delay: TimeInterval
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.milestoneCover = payload
        }
    }

    /// Muestra el prompt de recuperación una vez por sesión, y solo con la pantalla libre.
    func presentRecoveryPromptIfNeeded(candidate: @autoclosure () -> RecoveryPromptCandidate?) {
        guard !didShowRecoveryPromptThisSession,
              sheetRoute == nil,
              coverRoute == nil,
              let candidate = candidate() else {
            return
        }

        didShowRecoveryPromptThisSession = true
        sheetRoute = .recoveryPrompt(candidate)
    }

    /// Muestra la propuesta de reemplazo una vez que la hoja actual terminó de cerrarse.
    func presentReplacementPrompt(breakHabit: Habit, replacementHabit: Habit) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { [weak self] in
            guard let self, self.coverRoute == nil else { return }
            self.sheetRoute = .replacementPrompt(
                breakHabit: breakHabit,
                replacementHabit: replacementHabit
            )
        }
    }
}
