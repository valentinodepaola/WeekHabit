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

    private var category: HabitCategory {
        habit.displayCategory
    }

    private var trimmedNote: String? {
        guard let note = habit.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty else {
            return nil
        }
        return note
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
            CategoryBadgeView(category: category)

            Text(habit.title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.strongText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let trimmedNote {
                Text(trimmedNote)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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
            category: .learning,
            targetDaysPerWeek: 4,
            activeDaysOfWeek: [.monday, .tuesday, .thursday, .sunday]
        )
    )
}
