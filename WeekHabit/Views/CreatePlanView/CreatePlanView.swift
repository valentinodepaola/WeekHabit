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

    @State private var planName: String = ""
    @State private var motivation: String = ""
    @State private var endsAt: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var targetCompletionRate: Double = 0.8
    @State private var selectedHabits: Set<UUID> = []

    private let planToEdit: Plan?

    private var isSaveDisabled: Bool {
        planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isEditing: Bool {
        planToEdit != nil
    }

    private var isFirstPlan: Bool {
        !isEditing && allPlans.isEmpty
    }

    init(planToEdit: Plan? = nil) {
        self.planToEdit = planToEdit

        _planName = State(initialValue: planToEdit?.title ?? "")
        _motivation = State(initialValue: planToEdit?.motivation ?? "")
        _endsAt = State(initialValue: planToEdit?.endsAt ?? Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now)
        _targetCompletionRate = State(initialValue: planToEdit?.targetCompletionRate ?? 0.8)
        _selectedHabits = State(initialValue: Set(planToEdit?.habits.map(\.id) ?? []))
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
                        planName: $planName,
                        motivation: $motivation
                    )

                    PlanScheduleSection(
                        endsAt: $endsAt,
                        targetCompletionRate: $targetCompletionRate
                    )

                    PlanHabitsSection(selectedHabits: $selectedHabits)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.l)
                .padding(.bottom, AppSpacing.xxl)
            }
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

        let trimmedName = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMotivation = motivation.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEndsAt = AppCalendar.startOfDay(for: endsAt)
        let linkedHabits = allHabits.filter { selectedHabits.contains($0.id) }

        if let planToEdit {
            planToEdit.title = trimmedName
            planToEdit.motivation = trimmedMotivation.isEmpty ? nil : trimmedMotivation
            planToEdit.endsAt = normalizedEndsAt
            planToEdit.targetCompletionRate = targetCompletionRate
            planToEdit.habits = linkedHabits
        } else {
            let plan = Plan(
                title: trimmedName,
                motivation: trimmedMotivation.isEmpty ? nil : trimmedMotivation,
                endsAt: normalizedEndsAt,
                targetCompletionRate: targetCompletionRate
            )
            modelContext.insert(plan)
            plan.habits = linkedHabits
        }

        dismiss()
    }
}

#Preview {
    CreatePlanView()
}
