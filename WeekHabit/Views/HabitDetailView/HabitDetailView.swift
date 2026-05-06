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

    @State private var editRoute: DetailEditHabitRoute?

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

    private var currentStreak: Int {
        habit.currentStreak()
    }

    private var bestStreak: Int {
        habit.bestStreak()
    }

    private var completedThisWeek: Int {
        habit.completedDaysThisWeek()
    }

    private var weekProgress: Double {
        habit.weekProgress()
    }

    private var activeExperiment: HabitExperiment? {
        experiments.activeExperiment(for: habit.id)
    }

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar

                    header

                    CurrentStreakHeroCard(
                        habit: habit,
                        currentStreak: currentStreak,
                        bestStreak: bestStreak
                    )

                    HStack(spacing: 12) {
                        StatTileView(
                            caption: "ESTA SEMANA",
                            value: "\(completedThisWeek)/\(habit.targetDaysPerWeek)",
                            footer: "\(Int(weekProgress * 100))% de meta"
                        )

                        StatTileView(
                            caption: "MEJOR RACHA",
                            value: "\(bestStreak)",
                            footer: bestStreakFooter
                        )
                    }

                    WeekDotsCard(habit: habit)

                    LastWeeksHeatmapCard(habit: habit)
                }
                .padding(.horizontal, 16)
                .padding(.top, 15)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $editRoute) { route in
            CreateHabitView(habitToEdit: route.habit)
        }
    }

    private var topBar: some View {
        HStack {
            IconButton(icon: "chevron.left", style: .circle) {
                dismiss()
            }

            Spacer()

            IconButton(icon: "pencil", style: .circle) {
                editRoute = DetailEditHabitRoute(habit: habit)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconComponent(
                icon: habit.iconName,
                color: habit.habitColor
            )

            Text(habit.title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.strongText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let trimmedCue {
                cueLine(trimmedCue)
            }

            if let trimmedNote {
                Text(trimmedNote)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(detailSummary)
                .font(AppFont.formSectionText2)
                .foregroundStyle(AppColor.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let activeExperiment {
                HabitExperimentStatusCard(
                    experiment: activeExperiment,
                    habit: habit
                )
            }
        }
    }

    private var bestStreakFooter: String {
        if bestStreak == 0 {
            return "aún sin récord"
        }

        if currentStreak == bestStreak {
            return "hoy = récord"
        }

        return "tu mejor marca"
    }

    private var detailSummary: String {
        if habit.trackingKind == .quantity {
            return "\(habit.scheduleSummaryText) · \(habit.targetPerSessionText)"
        }

        return habit.scheduleSummaryText
    }

    private func cueLine(_ cue: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(habit.habitColor)

            Text(cue)
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailEditHabitRoute: Identifiable {
    let habit: Habit

    var id: UUID {
        habit.id
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
