//
//  TodayHabitListSection.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

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
    let showsUrgeExplainer: Bool
    let namespace: Namespace.ID
    let reduceMotion: Bool
    let onDismissFreezeExplainer: () -> Void
    let onDismissUrgeExplainer: () -> Void
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
                TodayFreezeBanner(
                    message: freezeMessage,
                    onDismiss: onDismissFreezeExplainer
                )
                    .todayListRow(
                        EdgeInsets(top: 0, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
                    )
            }

            sectionHeader(title: "Pendientes", count: pendingHabits.count)
                .todayListRow(
                    EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
                )

            // Fuera del grupo y arriba de él: dentro rompería el ritmo de las filas y se
            // deslizaría junto con una de ellas.
            if showsUrgeExplainer, let urgeHabit = firstBreakHabitForUrgeExplainer {
                TodayUrgeExplainer(color: urgeHabit.habitColor, onDismiss: onDismissUrgeExplainer)
                    .todayListRow()
            }

            ForEach(Array(pendingHabits.enumerated()), id: \.element.id) { index, habit in
                pendingRow(habit)
                    .todayGroupedRow(TodayGroupPosition(index: index, count: pendingHabits.count))
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

                ForEach(Array(completedHabits.enumerated()), id: \.element.id) { index, habit in
                    completedRow(habit)
                        .todayGroupedRow(TodayGroupPosition(index: index, count: completedHabits.count), tone: .muted)
                }
            }

            if !slippedHabits.isEmpty {
                sectionHeader(title: "Slips registrados", count: slippedHabits.count)
                    .padding(.top, AppSpacing.xl)
                    .todayListRow()

                ForEach(Array(slippedHabits.enumerated()), id: \.element.id) { index, habit in
                    slipRow(habit)
                        .todayGroupedRow(TodayGroupPosition(index: index, count: slippedHabits.count))
                }
            }

            if !skippedHabits.isEmpty {
                sectionHeader(title: "Descansos", count: skippedHabits.count)
                    .padding(.top, AppSpacing.xl)
                    .todayListRow()

                ForEach(Array(skippedHabits.enumerated()), id: \.element.id) { index, habit in
                    skippedRow(habit)
                        .todayGroupedRow(TodayGroupPosition(index: index, count: skippedHabits.count))
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

    private var firstBreakHabitForUrgeExplainer: Habit? {
        pendingHabits.first(where: { $0.isBreakHabit })
    }

    private func completedRow(_ habit: Habit) -> some View {
        TodayCompletedHabitRow(
            habit: habit,
            detail: habit.todayCompletionDetail(reference: referenceDate),
            isMinimumCompleted: habit.isMinimumCompleted(on: referenceDate) && !habit.isCompleted(on: referenceDate),
            weeklyRestNotice: habit.restsOnMetWeeklyTarget(on: referenceDate)
                ? habit.weeklyTargetRestNotice(reference: referenceDate)
                : nil,
            onOpenDetail: { actions.openDetail(habit) }
        ) {
            actions.toggleCompletion(habit)
        }
        .todayHabitSectionMotion(habit.id, in: namespace, reduceMotion: reduceMotion)
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

#Preview(traits: .sampleData) {
    @Previewable @Query(sort: \Habit.createdAt) var habits: [Habit]
    @Previewable @Query var experiments: [HabitExperiment]
    @Previewable @Namespace var namespace

    let todayHabits = habits.loggableToday(on: .now)
    let partition = todayHabits.todayPartition(on: .now)

    List {
        TodayHabitListSection(
            todayHabits: todayHabits,
            pendingHabits: partition.pending,
            completedHabits: partition.completed,
            skippedHabits: partition.skipped,
            slippedHabits: partition.slipped,
            experiments: experiments,
            referenceDate: .now,
            progress: partition.progress,
            completedCount: partition.completedCount,
            activeCount: partition.activeCount,
            remainingCount: partition.pending.count,
            slipCount: partition.slipped.count,
            freezeMessage: nil,
            showsUrgeExplainer: true,
            namespace: namespace,
            reduceMotion: false,
            onDismissFreezeExplainer: {},
            onDismissUrgeExplainer: {},
            actions: TodayHabitActions(
                toggleCompletion: { _ in },
                markMinimum: { _ in },
                openDetail: { _ in },
                openUrgeLog: { _ in },
                openSlipLog: { _ in },
                toggleRest: { _ in },
                requestDelete: { _ in },
                openEdit: { _ in },
                openSlipContext: { _ in },
                undoSlip: { _ in },
                startFocus: {}
            )
        )
    }
    .listStyle(.plain)
    .listRowSpacing(0)
    .scrollContentBackground(.hidden)
    .background(AppColor.bgCanvas)
}
