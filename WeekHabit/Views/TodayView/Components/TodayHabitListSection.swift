//
//  TodayHabitListSection.swift
//  WeekHabit
//

import SwiftUI

struct TodayHabitActions {
    var toggleCompletion: (Habit) -> Void
    var markMinimum: (Habit) -> Void
    var openDetail: (Habit) -> Void
    var openUrgeLog: (Habit) -> Void
    var openSlipLog: (Habit) -> Void
    var toggleRest: (Habit) -> Void
    var requestDelete: (Habit) -> Void
    var openEdit: (Habit) -> Void
    var openSlipContext: (Habit) -> Void
    var undoSlip: (Habit) -> Void
    var startFocus: () -> Void
}

struct TodayHabitListSection: View {
    let todayHabits: [Habit]
    let pendingHabits: [Habit]
    let completedHabits: [Habit]
    let skippedHabits: [Habit]
    let slippedHabits: [Habit]
    let experiments: [HabitExperiment]
    let referenceDate: Date
    let progress: Double
    let completedCount: Int
    let activeCount: Int
    let remainingCount: Int
    let slipCount: Int
    let freezeMessage: String?
    let namespace: Namespace.ID
    let reduceMotion: Bool
    let actions: TodayHabitActions

    var body: some View {
        Group {
            DailyProgressCard(
                progress: progress,
                completedCount: completedCount,
                totalCount: activeCount,
                remainingCount: remainingCount,
                slipCount: slipCount
            )
            .todayListRow(
                EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
            )

            if let freezeMessage {
                TodayFreezeBanner(message: freezeMessage)
                    .todayListRow(
                        EdgeInsets(top: 0, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
                    )
            }

            sectionHeader(title: "Pendientes", count: pendingHabits.count)
                .todayListRow(
                    EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
                )

            ForEach(pendingHabits) { habit in
                pendingRow(habit)
            }

            FocusSessionLauncherCard(
                remainingCount: remainingCount,
                onStart: actions.startFocus
            )
            .todayListRow()

            if !completedHabits.isEmpty {
                sectionHeader(title: "Completados", count: completedHabits.count)
                    .padding(.top, AppSpacing.xl)
                    .todayListRow()

                ForEach(completedHabits) { habit in
                    completedRow(habit)
                }
            }

            if !slippedHabits.isEmpty {
                sectionHeader(title: "Slips registrados", count: slippedHabits.count)
                    .padding(.top, AppSpacing.xl)
                    .todayListRow()

                ForEach(slippedHabits) { habit in
                    slipRow(habit)
                }
            }

            if !skippedHabits.isEmpty {
                sectionHeader(title: "Descansos", count: skippedHabits.count)
                    .padding(.top, AppSpacing.xl)
                    .todayListRow()

                ForEach(skippedHabits) { habit in
                    skippedRow(habit)
                }
            }

            if let top = todayHabits.topStreakHabit(reference: referenceDate) {
                let allSameStreak = todayHabits.allShareSameCurrentStreak(reference: referenceDate)
                LongestStreakBanner(
                    habit: allSameStreak ? nil : top.habit,
                    streakDays: top.streak,
                    allSameStreak: allSameStreak
                )
                .todayListRow()
            }
        }
    }

    private func pendingRow(_ habit: Habit) -> some View {
        TodayHabitComponent(
            habit: habit,
            isCompleted: false,
            isMinimumCompleted: habit.isMinimumCompleted(on: referenceDate),
            activeExperiment: experiments.activeExperiment(
                for: habit.id,
                reference: referenceDate
            ),
            referenceDate: referenceDate,
            onUrge: habit.isBreakHabit ? { actions.openUrgeLog(habit) } : nil,
            onSlip: habit.isBreakHabit ? { actions.openSlipLog(habit) } : nil,
            onMinimum: { actions.markMinimum(habit) },
            onOpenDetail: { actions.openDetail(habit) }
        ) {
            actions.toggleCompletion(habit)
        }
        .todayHabitSectionMotion(habit.id, in: namespace, reduceMotion: reduceMotion)
        .todayListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                actions.toggleRest(habit)
            } label: {
                Label("Hoy descanso", systemImage: "pause.circle")
            }
            .tint(habit.habitColor)

            Button(role: .destructive) {
                actions.requestDelete(habit)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                actions.openEdit(habit)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func completedRow(_ habit: Habit) -> some View {
        TodayCompletedHabitRow(
            habit: habit,
            metadata: habit.todayCompletionMetadata(reference: referenceDate),
            isMinimumCompleted: habit.isMinimumCompleted(on: referenceDate) && !habit.isCompleted(on: referenceDate),
            onOpenDetail: { actions.openDetail(habit) }
        ) {
            actions.toggleCompletion(habit)
        }
        .todayHabitSectionMotion(habit.id, in: namespace, reduceMotion: reduceMotion)
        .todayListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                actions.toggleRest(habit)
            } label: {
                Label("Hoy descanso", systemImage: "pause.circle")
            }
            .tint(habit.habitColor)

            Button(role: .destructive) {
                actions.requestDelete(habit)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                actions.openEdit(habit)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func slipRow(_ habit: Habit) -> some View {
        TodaySlipHabitRow(
            habit: habit,
            metadata: habit.todaySlipMetadata(reference: referenceDate),
            onEdit: { actions.openSlipContext(habit) },
            onUndo: { actions.undoSlip(habit) },
            onOpenDetail: { actions.openDetail(habit) }
        )
        .todayHabitSectionMotion(habit.id, in: namespace, reduceMotion: reduceMotion)
        .todayListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                actions.undoSlip(habit)
            } label: {
                Label("Deshacer slip", systemImage: "arrow.uturn.backward.circle")
            }
            .tint(AppColor.warning)

            Button {
                actions.openSlipContext(habit)
            } label: {
                Label("Editar contexto", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func skippedRow(_ habit: Habit) -> some View {
        TodayHabitComponent(
            habit: habit,
            isCompleted: false,
            isSkipped: true,
            activeExperiment: experiments.activeExperiment(
                for: habit.id,
                reference: referenceDate
            ),
            referenceDate: referenceDate,
            onOpenDetail: { actions.openDetail(habit) }
        ) {
            actions.toggleCompletion(habit)
        }
        .todayHabitSectionMotion(habit.id, in: namespace, reduceMotion: reduceMotion)
        .todayListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                actions.toggleRest(habit)
            } label: {
                Label("Quitar descanso", systemImage: "arrow.uturn.backward.circle")
            }
            .tint(habit.habitColor)

            Button(role: .destructive) {
                actions.requestDelete(habit)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                actions.openEdit(habit)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Text(count == 1 ? "1 hábito" : "\(count) hábitos")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}
