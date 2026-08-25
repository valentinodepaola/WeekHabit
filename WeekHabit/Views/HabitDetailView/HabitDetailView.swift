//
//  HabitDetailView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    let habit: Habit

    @State private var habitRoute: HabitRoute?

    private var trimmedNote: String? {
        guard let note = habit.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty else {
            return nil
        }
        return note
    }

    private var trimmedCue: String? {
        guard let cue = habit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }
        return cue
    }

    private var trimmedMinimumTitle: String? {
        guard let title = habit.minimumViableTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return nil
        }
        return title
    }

    private var currentStreak: Int { habit.currentStreak() }
    private var bestStreak: Int { habit.bestStreak() }
    private var streakBreakdown: StreakBreakdown { habit.currentStreakBreakdown() }
    private var completedThisWeek: Int { habit.completedDaysThisWeek() }
    private var weekProgress: Double { habit.weekProgress() }
    private var activeExperiment: HabitExperiment? {
        experiments.activeExperiment(for: habit.id)
    }

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    topBar

                    header

                    CurrentStreakHeroCard(
                        habit: habit,
                        currentStreak: currentStreak,
                        bestStreak: bestStreak
                    )

                    StreakBreakdownCard(
                        habit: habit,
                        breakdown: streakBreakdown,
                        color: habit.habitColor
                    )

                    HStack(spacing: AppSpacing.s) {
                        StatTileView(
                            caption: habit.isBreakHabit ? "ESTA SEMANA" : "ESTA SEMANA",
                            value: "\(completedThisWeek)/\(habit.targetDaysPerWeek)",
                            footer: habit.isBreakHabit
                                ? "\(completedThisWeek) \(completedThisWeek == 1 ? "día evitado" : "días evitados")"
                                : "\(Int(weekProgress * 100))% de meta"
                        )
                        StatTileView(
                            caption: "REFERENCIA",
                            value: "\(bestStreak)",
                            footer: bestStreakFooter
                        )
                    }

                    WeekDotsCard(habit: habit)

                    if habit.isBreakHabit {
                        SlipTimelineCard(habit: habit)
                    }

                    LastWeeksHeatmapCard(habit: habit, weeks: 52)
                }
                .padding(.horizontal, AppSpacing.l)
                .padding(.top, AppSpacing.l)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $habitRoute) { route in
            switch route {
            case .edit(let habit):
                CreateHabitView(habitToEdit: habit)
            case .create(let prefill):
                CreateHabitView(
                    initialDaysPerWeek: prefill.initialDaysPerWeek ?? 7,
                    initialActiveDays: prefill.initialActiveDays
                )
            }
        }
    }

    private var topBar: some View {
        HStack {
            IconButton(icon: "chevron.left", style: .circle) {
                dismiss()
            }

            Spacer()

            IconButton(icon: "pencil", style: .circle) {
                habitRoute = .edit(habit)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            ZStack {
                Circle()
                    .fill(habit.habitColor.opacity(0.18))
                    .frame(width: 60, height: 60)
                Image(systemName: habit.iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(habit.habitColor)
            }

            Text(habit.title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let trimmedCue {
                cueLine(trimmedCue)
            }

            if let trimmedNote {
                Text(trimmedNote)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(detailSummary)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let trimmedMinimumTitle {
                MinimumViableHabitCard(
                    title: trimmedMinimumTitle,
                    color: habit.habitColor
                )
                .padding(.top, AppSpacing.xs)
            }

            if let activeExperiment {
                HabitExperimentStatusCard(
                    experiment: activeExperiment,
                    habit: habit
                )
                .padding(.top, AppSpacing.xs)
            }

            if habit.isBreakHabit, let replacementHabit = habit.replacementHabit {
                ReplacementHabitCard(replacementHabit: replacementHabit)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }

    private var bestStreakFooter: String {
        IdentityReinforcementCopy.bestStreakFooter(
            for: habit,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }

    private var detailSummary: String {
        if habit.trackingKind == .quantity {
            return "\(habit.scheduleSummaryText) · \(habit.targetPerSessionText)"
        }
        return habit.scheduleSummaryText
    }

    private func cueLine(_ cue: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(habit.habitColor)
            Text(cue)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReplacementHabitCard: View {
    let replacementHabit: Habit

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: replacementHabit.iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(replacementHabit.habitColor)
                .frame(width: 36, height: 36)
                .background(replacementHabit.habitColor.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Reemplazo")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.4)

                Text(replacementHabit.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                if let cue = replacementCue {
                    Text(cue)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.divider, lineWidth: 1)
        }
    }

    private var replacementCue: String? {
        guard let cue = replacementHabit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }
        return cue
    }
}

private struct MinimumViableHabitCard: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("VERSIÓN MÍNIMA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.4)

                Text(title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.divider, lineWidth: 1)
        }
    }
}

#Preview {
    HabitDetailView(
        habit: Habit(
            title: "Leer 20 páginas",
            note: "Antes de dormir, sin celular cerca.",
            cue: "Después de lavarme los dientes",
            iconName: "book.fill",
            colorHex: "#5c89a8",
            targetDaysPerWeek: 4,
            activeDaysOfWeek: [.monday, .tuesday, .thursday, .sunday]
        )
    )
}
