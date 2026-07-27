//
//  HabitTrackingService.swift
//  WeekHabit
//

import Foundation
import SwiftData

struct HabitTrackingResult {
    let entry: HabitEntry?
    let wasCompleted: Bool
    let isCompleted: Bool

    var becameCompleted: Bool {
        !wasCompleted && isCompleted
    }
}

enum HabitTrackingService {
    static func toggleCompletion(
        for habit: Habit,
        on date: Date,
        source: HabitEntrySource,
        completedAt: Date?,
        modelContext: ModelContext,
        streakFreezes: [StreakFreeze]
    ) -> HabitTrackingResult {
        let wasCompleted = habit.isCompleted(on: date)

        if wasCompleted {
            completedEntries(for: habit, on: date).forEach { modelContext.delete($0) }
            return HabitTrackingResult(entry: nil, wasCompleted: true, isCompleted: false)
        }

        return setCompleted(
            habit,
            on: date,
            source: source,
            completedAt: completedAt,
            value: 1,
            focusSessionID: nil,
            modelContext: modelContext,
            streakFreezes: streakFreezes
        )
    }

    static func setCompleted(
        _ habit: Habit,
        on date: Date,
        source: HabitEntrySource,
        completedAt: Date?,
        value: Double,
        focusSessionID: UUID?,
        modelContext: ModelContext,
        streakFreezes: [StreakFreeze]
    ) -> HabitTrackingResult {
        let wasCompleted = habit.isCompleted(on: date)
        let entries = stateEntries(for: habit, on: date)
        let entry: HabitEntry

        if let existing = entries.first {
            existing.kind = .completed
            existing.completedAt = completedAt
            existing.source = source
            existing.focusSessionID = focusSessionID
            existing.value = value
            existing.completedCount = Int(value.rounded())
            entries.dropFirst().forEach { modelContext.delete($0) }
            entry = existing
        } else {
            entry = HabitEntry(
                date: date,
                completedAt: completedAt,
                source: source,
                focusSessionID: focusSessionID,
                completedCount: Int(value.rounded()),
                value: value,
                habit: habit
            )
            modelContext.insert(entry)
        }

        deleteFreeze(for: habit, on: date, from: streakFreezes, modelContext: modelContext)

        return HabitTrackingResult(
            entry: entry,
            wasCompleted: wasCompleted,
            isCompleted: value >= habit.sessionTargetValue
        )
    }

    static func upsertQuantity(
        for habit: Habit,
        on date: Date,
        value: Double,
        source: HabitEntrySource,
        completedAt: Date?,
        modelContext: ModelContext,
        streakFreezes: [StreakFreeze]
    ) -> HabitTrackingResult {
        let wasCompleted = habit.isCompleted(on: date)

        guard value > 0 else {
            stateEntries(for: habit, on: date)
                .filter { $0.kind == .completed || $0.kind == .minimum }
                .forEach { modelContext.delete($0) }
            return HabitTrackingResult(entry: nil, wasCompleted: wasCompleted, isCompleted: false)
        }

        return setCompleted(
            habit,
            on: date,
            source: source,
            completedAt: completedAt,
            value: value,
            focusSessionID: nil,
            modelContext: modelContext,
            streakFreezes: streakFreezes
        )
    }

    static func markMinimum(
        for habit: Habit,
        on date: Date,
        source: HabitEntrySource,
        completedAt: Date?,
        modelContext: ModelContext,
        streakFreezes: [StreakFreeze]
    ) -> HabitEntry? {
        guard !habit.isCompleted(on: date) else { return nil }

        stateEntries(for: habit, on: date).forEach { modelContext.delete($0) }
        deleteFreeze(for: habit, on: date, from: streakFreezes, modelContext: modelContext)

        let entry = HabitEntry(
            date: date,
            completedAt: completedAt,
            source: source,
            kind: .minimum,
            completedCount: 0,
            value: 0,
            habit: habit
        )
        modelContext.insert(entry)
        return entry
    }

    @discardableResult
    static func toggleRest(
        for habit: Habit,
        on date: Date,
        source: HabitEntrySource,
        modelContext: ModelContext,
        streakFreezes: [StreakFreeze]
    ) -> Bool {
        let willSkip = !habit.isSkipped(on: date)
        stateEntries(for: habit, on: date).forEach { modelContext.delete($0) }

        if willSkip {
            deleteFreeze(for: habit, on: date, from: streakFreezes, modelContext: modelContext)
            modelContext.insert(
                HabitEntry(
                    date: date,
                    completedAt: nil,
                    source: source,
                    kind: .skipped,
                    completedCount: 0,
                    value: 0,
                    habit: habit
                )
            )
        }

        return willSkip
    }

    @discardableResult
    static func recordSlip(
        for habit: Habit,
        on date: Date,
        trigger: SlipTrigger?,
        context: String?,
        modelContext: ModelContext,
        streakFreezes: [StreakFreeze]
    ) -> Bool {
        guard habit.isBreakHabit else { return false }

        let hadSlip = habit.isSlip(on: date)
        let entries = stateEntries(for: habit, on: date)

        if let existing = entries.first(where: { $0.kind == .slip }) {
            existing.completedAt = existing.completedAt ?? .now
            existing.source = .today
            existing.completedCount = 0
            existing.value = 0
            existing.slipTrigger = trigger
            existing.slipContext = context
            entries.filter { $0.id != existing.id }.forEach { modelContext.delete($0) }
        } else {
            entries.forEach { modelContext.delete($0) }
            modelContext.insert(
                HabitEntry(
                    date: date,
                    completedAt: .now,
                    source: .today,
                    kind: .slip,
                    completedCount: 0,
                    value: 0,
                    slipTrigger: trigger,
                    slipContext: context,
                    habit: habit
                )
            )
        }

        deleteFreeze(for: habit, on: date, from: streakFreezes, modelContext: modelContext)
        return !hadSlip
    }

    static func recordUrge(
        for habit: Habit,
        on date: Date,
        trigger: SlipTrigger?,
        modelContext: ModelContext
    ) {
        guard habit.isBreakHabit else { return }

        modelContext.insert(
            HabitEntry(
                date: date,
                completedAt: .now,
                source: .today,
                kind: .urge,
                completedCount: 0,
                value: 0,
                slipTrigger: trigger,
                habit: habit
            )
        )
    }

    static func undoSlip(for habit: Habit, on date: Date, modelContext: ModelContext) {
        habit.entries
            .filter { AppCalendar.isSameDay($0.date, date) && $0.kind == .slip }
            .forEach { modelContext.delete($0) }
    }

    static func recordRecoveryMiss(
        _ candidate: RecoveryPromptCandidate,
        reason: HabitFailureReason?,
        modelContext: ModelContext
    ) {
        let entries = stateEntries(for: candidate.habit, on: candidate.date)

        if let existing = entries.first(where: { $0.kind == .missed }) {
            existing.failureReasonKind = reason
            entries
                .filter { $0.kind == .missed && $0.id != existing.id }
                .forEach { modelContext.delete($0) }
            return
        }

        guard entries.isEmpty else { return }

        modelContext.insert(
            HabitEntry(
                date: candidate.date,
                completedAt: nil,
                source: .today,
                kind: .missed,
                completedCount: 0,
                value: 0,
                failureReason: reason,
                habit: candidate.habit
            )
        )
    }

    /// Registra el miss de recuperación y lo escribe a disco de inmediato.
    ///
    /// El prompt de recuperación se muestra una sola vez al día, así que su respuesta no
    /// puede quedar dependiendo del autosave. `minimumTitle` guarda, en el mismo paso, la
    /// versión mínima que el usuario define desde el prompt.
    static func commitRecoveryMiss(
        _ candidate: RecoveryPromptCandidate,
        reason: HabitFailureReason?,
        minimumTitle: String? = nil,
        modelContext: ModelContext
    ) throws {
        if let minimumTitle, !minimumTitle.isEmpty {
            candidate.habit.minimumViableTitle = minimumTitle
        }

        recordRecoveryMiss(candidate, reason: reason, modelContext: modelContext)

        try modelContext.save()
    }

    @discardableResult
    static func applyWeeklyFreezes(
        to habits: [Habit],
        existing streakFreezes: [StreakFreeze],
        reference: Date,
        modelContext: ModelContext
    ) -> [StreakFreeze] {
        var insertedFreezes: [StreakFreeze] = []

        for habit in habits where habit.allowsWeeklyFreeze {
            guard let protectedDate = habit.weeklyFreezeCandidate(reference: reference),
                  !streakFreezes.containsFreeze(for: habit, weekContaining: protectedDate) else {
                continue
            }

            let freeze = StreakFreeze(habit: habit, protectedDate: protectedDate)
            modelContext.insert(freeze)
            insertedFreezes.append(freeze)
        }

        return insertedFreezes
    }

    private static func stateEntries(for habit: Habit, on date: Date) -> [HabitEntry] {
        habit.entries.filter {
            AppCalendar.isSameDay($0.date, date) && $0.kind != .urge
        }
    }

    private static func completedEntries(for habit: Habit, on date: Date) -> [HabitEntry] {
        stateEntries(for: habit, on: date).filter { $0.kind == .completed }
    }

    private static func deleteFreeze(
        for habit: Habit,
        on date: Date,
        from streakFreezes: [StreakFreeze],
        modelContext: ModelContext
    ) {
        streakFreezes
            .filter { $0.habitID == habit.id && AppCalendar.isSameDay($0.protectedDate, date) }
            .forEach { modelContext.delete($0) }
    }
}
