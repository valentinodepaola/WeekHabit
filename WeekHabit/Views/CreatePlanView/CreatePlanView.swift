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
    @State private var measurableOutcome: String = ""
    @State private var endsAt: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var targetCompletionRate: Double = 0.8
    @State private var selectedHabits: Set<UUID> = []
    @State private var milestoneDrafts: [MilestoneDraft] = []

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
        _measurableOutcome = State(initialValue: planToEdit?.measurableOutcome ?? "")
        _endsAt = State(initialValue: planToEdit?.endsAt ?? Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now)
        _targetCompletionRate = State(initialValue: planToEdit?.targetCompletionRate ?? 0.8)
        _selectedHabits = State(initialValue: Set(planToEdit?.habits.map(\.id) ?? []))
        _milestoneDrafts = State(initialValue: (planToEdit?.milestones ?? [])
            .sorted { $0.targetDate < $1.targetDate }
            .map { MilestoneDraft(id: $0.id, title: $0.title, targetDate: $0.targetDate) }
        )
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

                    PlanMeasurableSection(measurableOutcome: $measurableOutcome)

                    PlanScheduleSection(
                        endsAt: $endsAt,
                        targetCompletionRate: $targetCompletionRate
                    )

                    PlanMilestonesSection(milestones: $milestoneDrafts, planEndsAt: endsAt)

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
        let trimmedOutcome = measurableOutcome.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEndsAt = AppCalendar.startOfDay(for: endsAt)
        let linkedHabits = allHabits.filter { selectedHabits.contains($0.id) }

        if let planToEdit {
            planToEdit.title = trimmedName
            planToEdit.motivation = trimmedMotivation.isEmpty ? nil : trimmedMotivation
            planToEdit.measurableOutcome = trimmedOutcome.isEmpty ? nil : trimmedOutcome
            planToEdit.endsAt = normalizedEndsAt
            planToEdit.targetCompletionRate = targetCompletionRate
            planToEdit.habits = linkedHabits
            reconcileMilestones(for: planToEdit)
        } else {
            let plan = Plan(
                title: trimmedName,
                motivation: trimmedMotivation.isEmpty ? nil : trimmedMotivation,
                measurableOutcome: trimmedOutcome.isEmpty ? nil : trimmedOutcome,
                endsAt: normalizedEndsAt,
                targetCompletionRate: targetCompletionRate
            )
            modelContext.insert(plan)
            plan.habits = linkedHabits
            for draft in milestoneDrafts where !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                modelContext.insert(PlanMilestone(title: draft.title, targetDate: draft.targetDate, plan: plan))
            }
        }

        dismiss()
    }

    private func reconcileMilestones(for plan: Plan) {
        let existingByID = Dictionary(uniqueKeysWithValues: plan.milestones.map { ($0.id, $0) })
        let draftIDs = Set(milestoneDrafts.map(\.id))

        for milestone in plan.milestones where !draftIDs.contains(milestone.id) {
            modelContext.delete(milestone)
        }

        for draft in milestoneDrafts {
            let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }
            if let existing = existingByID[draft.id] {
                existing.title = trimmedTitle
                existing.targetDate = AppCalendar.startOfDay(for: draft.targetDate)
            } else {
                modelContext.insert(PlanMilestone(title: trimmedTitle, targetDate: draft.targetDate, plan: plan))
            }
        }
    }
}

#Preview {
    CreatePlanView()
}
