//
//  PlanEditorService.swift
//  WeekHabit
//

import SwiftData

enum PlanEditorService {
    static func save(
        draft: PlanDraft,
        editing planToEdit: Plan?,
        allHabits: [Habit],
        modelContext: ModelContext
    ) throws -> Plan {
        let linkedHabits = allHabits.filter { draft.selectedHabitIDs.contains($0.id) }
        let savedPlan: Plan

        if let planToEdit {
            apply(draft, to: planToEdit, linkedHabits: linkedHabits)
            reconcileMilestones(from: draft, for: planToEdit, modelContext: modelContext)
            savedPlan = planToEdit
        } else {
            let plan = Plan(
                title: draft.normalizedName,
                motivation: draft.normalizedMotivation,
                measurableOutcome: draft.normalizedMeasurableOutcome,
                endsAt: draft.normalizedEndsAt,
                targetCompletionRate: draft.targetCompletionRate
            )
            modelContext.insert(plan)
            plan.habits = linkedHabits
            reconcileMilestones(from: draft, for: plan, modelContext: modelContext)
            savedPlan = plan
        }

        try modelContext.save()
        return savedPlan
    }

    private static func apply(_ draft: PlanDraft, to plan: Plan, linkedHabits: [Habit]) {
        plan.title = draft.normalizedName
        plan.motivation = draft.normalizedMotivation
        plan.measurableOutcome = draft.normalizedMeasurableOutcome
        plan.endsAt = draft.normalizedEndsAt
        plan.targetCompletionRate = draft.targetCompletionRate
        plan.habits = linkedHabits
    }

    private static func reconcileMilestones(
        from draft: PlanDraft,
        for plan: Plan,
        modelContext: ModelContext
    ) {
        let milestones = draft.normalizedMilestones
        let existingByID = Dictionary(uniqueKeysWithValues: plan.milestones.map { ($0.id, $0) })
        let milestoneIDs = Set(milestones.map(\.id))

        for milestone in plan.milestones where !milestoneIDs.contains(milestone.id) {
            modelContext.delete(milestone)
        }

        for milestone in milestones {
            if let existing = existingByID[milestone.id] {
                existing.title = milestone.title
                existing.targetDate = milestone.targetDate
            } else {
                modelContext.insert(
                    PlanMilestone(
                        title: milestone.title,
                        targetDate: milestone.targetDate,
                        plan: plan
                    )
                )
            }
        }
    }
}
