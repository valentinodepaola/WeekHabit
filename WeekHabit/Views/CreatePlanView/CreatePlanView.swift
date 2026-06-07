//
//  CreatePlanView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct CreatePlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @Query(sort: \Plan.createdAt, order: .reverse) private var allPlans: [Plan]

    @State private var draft: PlanDraft
    @State private var saveFailure: PlanSaveFailure?

    private let planToEdit: Plan?

    private var isSaveDisabled: Bool {
        draft.isSaveDisabled
    }

    private var isEditing: Bool {
        planToEdit != nil
    }

    private var isFirstPlan: Bool {
        !isEditing && allPlans.isEmpty
    }

    init(planToEdit: Plan? = nil) {
        self.planToEdit = planToEdit
        _draft = State(initialValue: PlanDraft(plan: planToEdit))
    }

    var body: some View {
        AppBackground {
            ScrollView {
                CreatePlanTopBar(
                    isSaveDisabled: isSaveDisabled,
                    onCancel: { dismiss() },
                    onSave: { savePlan() }
                )

                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text(isEditing ? "Editar plan" : "Nuevo plan")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.bottom, AppSpacing.xs)

                    if isFirstPlan {
                        firstPlanIntroCard
                    }

                    PlanBasicInfoSection(
                        planName: $draft.name,
                        motivation: $draft.motivation
                    )

                    PlanMeasurableSection(measurableOutcome: $draft.measurableOutcome)

                    PlanScheduleSection(
                        endsAt: $draft.endsAt,
                        targetCompletionRate: $draft.targetCompletionRate
                    )

                    PlanMilestonesSection(milestones: $draft.milestones, planEndsAt: draft.endsAt)

                    PlanHabitsSection(selectedHabits: $draft.selectedHabitIDs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.l)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .alert(item: $saveFailure) { failure in
            Alert(
                title: Text("No se pudo guardar"),
                message: Text(failure.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }

    private var firstPlanIntroCard: some View {
        WHCard(variant: .elevated, padding: AppSpacing.l, radius: AppRadius.l) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HStack(spacing: AppSpacing.s) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                    Text("TU PRIMER PLAN")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(0.8)
                }

                Text("Hábitos con propósito")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Un plan agrupa los hábitos que te llevan a una meta concreta. Al terminar, decides qué se mantiene y qué cumplió su función.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func savePlan() {
        guard !isSaveDisabled else { return }

        do {
            _ = try PlanEditorService.save(
                draft: draft,
                editing: planToEdit,
                allHabits: allHabits,
                modelContext: modelContext
            )
        } catch {
            saveFailure = PlanSaveFailure(message: error.localizedDescription)
            return
        }

        dismiss()
    }
}

private struct PlanSaveFailure: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    CreatePlanView()
}
