//
//  RecoveryPromptSheet.swift
//  WeekHabit
//

import SwiftUI

/// Contenedor de la hoja de recuperación: congela el roster de pendientes de ayer y es dueño de
/// la navegación entre la lista y el formulario de cada hábito.
///
/// El roster se congela a propósito. Contestar escribe una entrada `.missed`, así que el hábito
/// deja de ser candidato; con la lista derivada en vivo la fila se esfumaría en vez de quedar
/// confirmada, y el conteo del encabezado cambiaría bajo el dedo. El estado de cada fila sí sale
/// en vivo del `@Model`.
struct RecoveryPromptSheet: View {
    let referenceDate: Date
    /// Devuelve si el guardado prosperó; con `false` la vista se queda donde está y la alerta ya
    /// quedó puesta por quien persiste.
    let onSave: (RecoveryPromptCandidate, HabitFailureReason) -> Bool

    @Environment(\.dismiss) private var dismiss

    /// El roster se fija al construir la vista, no en un `.task`: sembrarlo después dejaba un
    /// primer frame con la lista vacía y, si el `@State` ya se había creado, se quedaba así.
    @State private var roster: [RecoveryPromptCandidate]
    @State private var path: [RecoveryPromptCandidate] = []

    init(
        candidates: [RecoveryPromptCandidate],
        referenceDate: Date,
        onSave: @escaping (RecoveryPromptCandidate, HabitFailureReason) -> Bool
    ) {
        self.referenceDate = referenceDate
        self.onSave = onSave
        _roster = State(initialValue: candidates)
    }

    var body: some View {
        Group {
            if roster.count == 1, let only = roster.first {
                // Con un solo pendiente la lista sería una fila: se abre el formulario directo.
                form(for: only)
                    .presentationDetents([.height(520), .medium])
            } else {
                NavigationStack(path: $path) {
                    RecoveryPromptListView(
                        candidates: roster,
                        onSelect: { path.append($0) }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: RecoveryPromptCandidate.self) { candidate in
                        form(for: candidate)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .presentationDetents([.large])
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.bgCanvas)
        .task {
            // Red de seguridad: sin pendientes no hay nada que preguntar. Ni la auto-presentación
            // ni el banner deberían llegar acá, pero una hoja vacía sería peor que ninguna.
            if roster.isEmpty { dismiss() }
        }
    }

    private func form(for candidate: RecoveryPromptCandidate) -> some View {
        RecoveryPromptView(
            candidate: candidate,
            referenceDate: referenceDate,
            onSave: { reason in
                guard onSave(candidate, reason) else { return }
                handleSaved()
            }
        )
    }

    /// Vuelve a la lista, y cierra la hoja cuando ya no queda nada por contestar.
    private func handleSaved() {
        let remaining = roster.filter { $0.habit.recoveryAnswer(on: $0.date) == nil }
        guard !remaining.isEmpty else {
            dismiss()
            return
        }

        path.removeAll()
    }
}
