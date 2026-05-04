//
//  PlanHabitsSection.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct PlanHabitsSection: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @Binding var selectedHabits: Set<UUID>

    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isFinished() }
    }

    var body: some View {
        CreateHabitFormSection(title: "Hábitos") {
            if activeHabits.isEmpty {
                Text("No tienes hábitos activos todavía. Crea uno primero desde la pantalla de Hábitos.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.subtleText)
                    .multilineTextAlignment(.leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(activeHabits) { habit in
                        HabitSelectionRow(
                            habit: habit,
                            isSelected: selectedHabits.contains(habit.id)
                        ) {
                            if selectedHabits.contains(habit.id) {
                                selectedHabits.remove(habit.id)
                            } else {
                                selectedHabits.insert(habit.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct HabitSelectionRow: View {
    let habit: Habit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(habit.habitColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: habit.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(habit.habitColor)
                }

                Text(habit.title)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.accent : AppColor.subtleText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
