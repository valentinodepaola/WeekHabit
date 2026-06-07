//
//  HabitEditorService.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum HabitEditorService {
    static func save(
        draft: HabitDraft,
        editing habitToEdit: Habit?,
        experiments: [HabitExperiment],
        allPlans: [Plan],
        allHabits: [Habit],
        requiredPlans: [Plan],
        locksPlanSelection: Bool,
        canScheduleReminders: Bool,
        modelContext: ModelContext
    ) throws -> Habit {
        let replacementHabit = resolveReplacementHabit(
            from: draft,
            allHabits: allHabits,
            modelContext: modelContext
        )
        let linkedPlans = resolveLinkedPlans(
            from: draft,
            allPlans: allPlans,
            requiredPlans: requiredPlans,
            locksPlanSelection: locksPlanSelection
        )
        let schedule = draft.normalizedSchedule
        let reminderEnabled = draft.isReminderEnabled && canScheduleReminders
        let savedHabit: Habit

        if let habitToEdit {
            experiments.activeExperiment(for: habitToEdit.id)?.cancel()
            apply(
                draft,
                to: habitToEdit,
                replacementHabit: replacementHabit,
                linkedPlans: linkedPlans,
                schedule: schedule,
                reminderEnabled: reminderEnabled
            )
            savedHabit = habitToEdit
        } else {
            let habit = makeHabit(
                from: draft,
                replacementHabit: replacementHabit,
                schedule: schedule,
                reminderEnabled: reminderEnabled
            )
            modelContext.insert(habit)
            habit.plans = linkedPlans
            savedHabit = habit
        }

        try modelContext.save()
        return savedHabit
    }

    private static func apply(
        _ draft: HabitDraft,
        to habit: Habit,
        replacementHabit: Habit?,
        linkedPlans: [Plan],
        schedule: (targetDaysPerWeek: Int, activeDays: Set<Weekday>),
        reminderEnabled: Bool
    ) {
        habit.title = trimmed(draft.name)
        habit.note = optionalTrimmed(draft.note)
        habit.cue = optionalTrimmed(draft.cue)
        habit.minimumViableTitle = optionalTrimmed(draft.minimumViableTitle)
        habit.iconName = draft.iconName
        habit.colorHex = draft.colorHex
        habit.direction = draft.direction
        habit.replacementHabit = draft.direction == .break ? replacementHabit : nil
        habit.trackingKind = draft.trackingKind
        habit.measurementUnit = draft.normalizedMeasurementUnit
        habit.customUnitName = nil
        habit.targetValuePerSession = draft.normalizedTargetValue
        habit.scheduleKind = draft.scheduleKind
        habit.targetDaysPerWeek = schedule.targetDaysPerWeek
        habit.activeDaysOfWeek = schedule.activeDays
        habit.endsAt = draft.normalizedEndsAt
        habit.allowsWeeklyFreeze = draft.allowsWeeklyFreeze
        habit.isReminderEnabled = reminderEnabled
        habit.reminderTime = reminderEnabled ? draft.reminderTime : nil
        habit.plans = linkedPlans
    }

    private static func makeHabit(
        from draft: HabitDraft,
        replacementHabit: Habit?,
        schedule: (targetDaysPerWeek: Int, activeDays: Set<Weekday>),
        reminderEnabled: Bool
    ) -> Habit {
        Habit(
            title: trimmed(draft.name),
            note: optionalTrimmed(draft.note),
            cue: optionalTrimmed(draft.cue),
            minimumViableTitle: optionalTrimmed(draft.minimumViableTitle),
            iconName: draft.iconName,
            colorHex: draft.colorHex,
            targetDaysPerWeek: schedule.targetDaysPerWeek,
            activeDaysOfWeek: schedule.activeDays,
            trackingKind: draft.trackingKind,
            measurementUnit: draft.normalizedMeasurementUnit,
            customUnitName: nil,
            targetValuePerSession: draft.normalizedTargetValue,
            scheduleKind: draft.scheduleKind,
            endsAt: draft.normalizedEndsAt,
            direction: draft.direction,
            replacementHabit: draft.direction == .break ? replacementHabit : nil,
            allowsWeeklyFreeze: draft.allowsWeeklyFreeze,
            isReminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? draft.reminderTime : nil
        )
    }

    private static func resolveReplacementHabit(
        from draft: HabitDraft,
        allHabits: [Habit],
        modelContext: ModelContext
    ) -> Habit? {
        guard draft.direction == .break else { return nil }

        switch draft.replacementMode {
        case .skip:
            return nil
        case .existing:
            guard let replacementHabitID = draft.replacementHabitID else { return nil }
            return allHabits.first { $0.id == replacementHabitID }
        case .create:
            let name = trimmed(draft.newReplacementHabitName)
            guard !name.isEmpty else { return nil }

            let habit = Habit(
                title: name,
                cue: optionalTrimmed(draft.newReplacementHabitCue),
                iconName: "figure.mind.and.body",
                colorHex: draft.colorHex,
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered),
                scheduleKind: .daily,
                direction: .build
            )
            modelContext.insert(habit)
            return habit
        }
    }

    private static func resolveLinkedPlans(
        from draft: HabitDraft,
        allPlans: [Plan],
        requiredPlans: [Plan],
        locksPlanSelection: Bool
    ) -> [Plan] {
        let requiredIDs = Set(requiredPlans.map(\.id))
        let selectedIDs = locksPlanSelection ? requiredIDs : draft.selectedPlanIDs.union(requiredIDs)
        var linkedPlans = allPlans.filter { selectedIDs.contains($0.id) }

        for requiredPlan in requiredPlans where !linkedPlans.contains(where: { $0.id == requiredPlan.id }) {
            linkedPlans.append(requiredPlan)
        }

        return linkedPlans
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func optionalTrimmed(_ value: String) -> String? {
        let value = trimmed(value)
        return value.isEmpty ? nil : value
    }
}
