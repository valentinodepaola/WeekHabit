//
//  TodayViewActions.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

/// Mutaciones de Hoy. Siguen en la vista porque necesitan `modelContext` y `withAnimation`,
/// pero se agrupan acá para que `TodayView` quede con la estructura de la pantalla.
/// Toda escritura pasa por un servicio; ninguna toca `modelContext` directo.
extension TodayView {
    // MARK: - Actions

    func toggleCompletion(for habit: Habit, data: TodayViewData, on date: Date) {
        if habit.trackingKind == .quantity {
            model.sheetRoute = .quantityLog(habit: habit, date: date)
            return
        }

        let willComplete = !habit.isCompleted(on: date)
        let closesDay = willComplete && data.remainingCount == 1
        var result: HabitTrackingResult?

        transitionHabitBetweenSections {
            result = HabitTrackingService.toggleCompletion(
                for: habit,
                on: date,
                source: .today,
                completedAt: .now,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if closesDay {
            playDayClosedHaptic()
        }

        if willComplete, let insertedEntry = result?.entry {
            presentLiveMilestoneIfNeeded(
                for: habit,
                on: date,
                noteEntry: insertedEntry,
                afterDayClosed: closesDay
            )
        }
    }

    func markMinimumCompleted(for habit: Habit, data: TodayViewData, on date: Date) {
        guard !habit.isCompleted(on: date) else { return }

        let closesDay = data.remainingCount == 1

        transitionHabitBetweenSections {
            _ = HabitTrackingService.markMinimum(
                for: habit,
                on: date,
                source: .today,
                completedAt: .now,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if closesDay {
            playDayClosedHaptic()
        }

        presentLiveMilestoneIfNeeded(for: habit, on: date, afterDayClosed: closesDay)
    }

    func presentLiveMilestoneIfNeeded(
        for habit: Habit,
        on date: Date,
        noteEntry: HabitEntry? = nil,
        afterDayClosed: Bool = false
    ) {
        guard let milestone = habit.crossedMilestone(on: date) else {
            if let noteEntry {
                model.requestNoteEntry(noteEntry)
            }
            return
        }

        habit.markMilestoneCelebrated(milestone)
        model.presentMilestone(
            MilestoneCelebrationPayload(habit: habit, milestone: milestone),
            noteEntry: noteEntry,
            after: afterDayClosed ? 1.75 : 0.6
        )
    }

    /// La háptica de cierre de día espera a que termine la animación de la lista.
    func playDayClosedHaptic() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            AppHaptics.play(.dayClosed)
        }
    }

    func applyWeeklyFreezes(reference: Date) {
        let insertedFreezes = HabitTrackingService.applyWeeklyFreezes(
            to: habits,
            existing: streakFreezes,
            reference: reference,
            modelContext: modelContext
        )

        if !insertedFreezes.isEmpty && !hasSeenFreezeExplainer {
            model.latestFreezeExplainerMessage = insertedFreezes.todayBannerMessage()
        }
    }

    func weekRangeText(for weekStart: Date) -> String {
        let weekEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(AppFormatters.string(from: weekStart, format: "d MMM")) - \(AppFormatters.string(from: weekEnd, format: "d MMM"))"
    }

    func upsertQuantityEntry(
        for habit: Habit,
        on date: Date,
        value: Double,
        source: HabitEntrySource,
        data: TodayViewData,
        reference: Date
    ) {
        let wasCompleted = habit.isCompleted(on: date)
        let closesDay = source == .today
            && AppCalendar.isSameDay(date, reference)
            && !wasCompleted
            && data.remainingCount == 1
        var result: HabitTrackingResult?

        transitionHabitBetweenSections {
            result = HabitTrackingService.upsertQuantity(
                for: habit,
                on: date,
                value: value,
                source: source,
                completedAt: source == .manual ? nil : .now,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        guard value > 0 else { return }

        if result?.becameCompleted == true {
            AppHaptics.play(.quantityCompleted)
            if closesDay {
                playDayClosedHaptic()
            }
            if source == .today {
                presentLiveMilestoneIfNeeded(for: habit, on: date, afterDayClosed: closesDay)
            }
        } else if result?.isCompleted == false {
            AppHaptics.play(.quantityLogged)
        }
    }

    func toggleRest(for habit: Habit, on date: Date) {
        transitionHabitBetweenSections {
            HabitTrackingService.toggleRest(
                for: habit,
                on: date,
                source: .today,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        AppHaptics.play(.skipToggled)
    }

    func persistSlip(for habit: Habit, trigger: SlipTrigger?, context: String?, on date: Date) {
        var didCreateSlip = false

        transitionHabitBetweenSections {
            didCreateSlip = HabitTrackingService.recordSlip(
                for: habit,
                on: date,
                trigger: trigger,
                context: context,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if didCreateSlip, let replacementHabit = habit.replacementHabit {
            model.presentReplacementPrompt(breakHabit: habit, replacementHabit: replacementHabit)
        }
    }

    func persistUrge(for habit: Habit, trigger: SlipTrigger?, on date: Date) {
        HabitTrackingService.recordUrge(
            for: habit,
            on: date,
            trigger: trigger,
            modelContext: modelContext
        )

        if let replacementHabit = habit.replacementHabit {
            model.presentReplacementPrompt(breakHabit: habit, replacementHabit: replacementHabit)
        }
    }

    func undoSlip(for habit: Habit, on date: Date) {
        transitionHabitBetweenSections {
            HabitTrackingService.undoSlip(
                for: habit,
                on: date,
                modelContext: modelContext
            )
        }
    }

    func persistRecoveryMiss(_ candidate: RecoveryPromptCandidate, reason: HabitFailureReason?) {
        guard commitRecoveryMiss(candidate, reason: reason) else { return }

        model.sheetRoute = nil
    }

    func createMinimumVersion(for candidate: RecoveryPromptCandidate, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard commitRecoveryMiss(candidate, reason: nil, minimumTitle: trimmedTitle) else { return }

        model.sheetRoute = nil
        AppHaptics.play(.selection)
    }

    /// Devuelve `false` y muestra la alerta si el guardado falla.
    func commitRecoveryMiss(
        _ candidate: RecoveryPromptCandidate,
        reason: HabitFailureReason?,
        minimumTitle: String? = nil
    ) -> Bool {
        do {
            try HabitTrackingService.commitRecoveryMiss(
                candidate,
                reason: reason,
                minimumTitle: minimumTitle,
                modelContext: modelContext
            )
            return true
        } catch {
            model.failure = .saving(error)
            return false
        }
    }

    func transitionHabitBetweenSections(_ mutation: @escaping () -> Void) {
        guard let animation = AppMotion.respectful(AppMotion.gentle, reduceMotion) else {
            withoutTodayListAnimation(mutation)
            return
        }

        withAnimation(animation) {
            mutation()
        }
    }

    func withoutTodayListAnimation(_ mutation: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            mutation()
        }
    }

    func deleteSelectedHabit() {
        guard let habitToDelete = model.habitToDelete else { return }
        let habitID = habitToDelete.id

        do {
            try withAnimation(AppMotion.smooth) {
                try HabitLifecycleService.delete(habitToDelete, modelContext: modelContext)
            }
        } catch {
            model.failure = .deleting(error)
            return
        }

        Task {
            await HabitReminderService.cancelReminder(forHabitID: habitID)
        }

        model.habitToDelete = nil
    }

    func deleteSelectedPlan() {
        guard let planToDelete = model.planToDelete else { return }

        do {
            try withAnimation(AppMotion.smooth) {
                try PlanLifecycleService.delete(planToDelete, modelContext: modelContext)
            }
        } catch {
            model.failure = .deleting(error)
            return
        }

        model.planToDelete = nil
    }
}
