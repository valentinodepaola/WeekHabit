//
//  PerformanceSeedToolsCard.swift
//  WeekHabit
//

#if DEBUG
import SwiftData
import SwiftUI

struct PerformanceSeedToolsCard: View {
    @Environment(\.modelContext) private var modelContext

    let habits: [Habit]
    let referenceDate: Date

    @State private var pendingAction: PerformanceSeedAction?
    @State private var feedback: String?
    @State private var failure: PerformanceSeedFailure?

    private var hasSeed: Bool {
        PerformanceSeedService.hasSeed(in: habits)
    }

    var body: some View {
        WHCard {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                header

                Text(descriptionText)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                WHButton(
                    title: hasSeed ? "Borrar datos de rendimiento" : "Crear datos de rendimiento",
                    icon: hasSeed ? "trash" : "chart.bar.doc.horizontal",
                    variant: .secondary
                ) {
                    feedback = nil
                    pendingAction = hasSeed ? .remove : .create
                }

                if let feedback {
                    Label(feedback, systemImage: "checkmark.circle.fill")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.success)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .confirmationDialog(
            pendingAction?.title ?? "",
            isPresented: isConfirmingAction,
            titleVisibility: .visible,
            presenting: pendingAction
        ) { action in
            switch action {
            case .create:
                Button("Crear") {
                    createSeed()
                }
            case .remove:
                Button("Borrar", role: .destructive) {
                    removeSeed()
                }
            }

            Button("Cancelar", role: .cancel) {}
        } message: { action in
            Text(action.message)
        }
        .alert(item: $failure) { failure in
            Alert(
                title: Text("No se pudo completar la acción"),
                message: Text(failure.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "hammer.fill")
                .font(AppFont.iconMedium)
                .foregroundStyle(AppColor.warning)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("HERRAMIENTAS DEBUG")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)

                Text("Datos de rendimiento")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    private var descriptionText: String {
        if hasSeed {
            return "Los datos sintéticos ya existen. Puedes borrarlos sin tocar tus hábitos reales."
        }

        let preview = PerformanceSeedService.preview
        return "Crea \(preview.habitCount) hábitos y alrededor de \(preview.approximateEntryCount.formatted()) registros sintéticos para medir Semana e Insights."
    }

    private var isConfirmingAction: Binding<Bool> {
        Binding(
            get: { pendingAction != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingAction = nil
                }
            }
        )
    }

    private func createSeed() {
        pendingAction = nil

        do {
            let result = try PerformanceSeedService.seedIfNeeded(
                existingHabits: habits,
                reference: referenceDate,
                modelContext: modelContext
            )

            if result.skippedBecauseSeedExists {
                feedback = "Los datos de rendimiento ya existían."
            } else {
                feedback = "Se crearon \(result.insertedHabitCount) hábitos y \(result.insertedEntryCount.formatted()) registros."
            }
        } catch {
            failure = PerformanceSeedFailure(
                message: "No se pudieron crear los datos de rendimiento. \(error.localizedDescription)"
            )
        }
    }

    private func removeSeed() {
        pendingAction = nil

        do {
            let result = try PerformanceSeedService.removeSeed(
                existingHabits: habits,
                modelContext: modelContext
            )

            if result.removedHabitCount == 0 {
                feedback = "No había datos de rendimiento para borrar."
            } else if result.removedExperimentCount > 0 {
                feedback = "Se borraron \(result.removedHabitCount) hábitos de rendimiento y \(result.removedExperimentCount) experimentos que los usaban."
            } else {
                feedback = "Se borraron \(result.removedHabitCount) hábitos de rendimiento."
            }
        } catch {
            failure = PerformanceSeedFailure(
                message: "No se pudieron borrar los datos de rendimiento. \(error.localizedDescription)"
            )
        }
    }
}

private enum PerformanceSeedAction {
    case create
    case remove

    var title: String {
        switch self {
        case .create:
            return "¿Crear datos de rendimiento?"
        case .remove:
            return "¿Borrar datos de rendimiento?"
        }
    }

    var message: String {
        switch self {
        case .create:
            let preview = PerformanceSeedService.preview
            return "Se agregarán \(preview.habitCount) hábitos y alrededor de \(preview.approximateEntryCount.formatted()) registros sintéticos. Tus datos actuales no se modificarán."
        case .remove:
            return "Se eliminarán todos los hábitos cuyo nombre comience con [Perf], sus registros y los experimentos que los usen. Tus otros hábitos no se modificarán."
        }
    }
}

private struct PerformanceSeedFailure: Identifiable {
    let id = UUID()
    let message: String
}
#endif
