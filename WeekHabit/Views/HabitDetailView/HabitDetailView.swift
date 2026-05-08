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

    private var currentStreak: Int { habit.currentStreak() }
    private var bestStreak: Int { habit.bestStreak() }
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

                    HStack(spacing: AppSpacing.s) {
                        StatTileView(
                            caption: "ESTA SEMANA",
                            value: "\(completedThisWeek)/\(habit.targetDaysPerWeek)",
                            footer: "\(Int(weekProgress * 100))% de meta"
                        )
                        StatTileView(
                            caption: "REFERENCIA",
                            value: "\(bestStreak)",
                            footer: bestStreakFooter
                        )
                    }

                    WeekDotsCard(habit: habit)

                    LastWeeksHeatmapCard(habit: habit)
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

            if let activeExperiment {
                HabitExperimentStatusCard(
                    experiment: activeExperiment,
                    habit: habit
                )
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    private var bestStreakFooter: String {
        if bestStreak == 0 {
            return "lista para empezar"
        }
        if currentStreak == bestStreak {
            return "la estás construyendo hoy"
        }
        return "tu marca para volver"
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
