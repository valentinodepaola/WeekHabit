//
//  PlanHabitsSection.swift
//  WeekHabit
//
//  Sección "Con qué hábitos": selección de hábitos activos a vincular.
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
        WHFormSection(
            title: "Con qué hábitos",
            helper: "Elige los hábitos pequeños que sostienen esta meta."
        ) {
            if activeHabits.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppSpacing.s) {
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

    private var emptyState: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "leaf")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.textTertiary)
                .frame(width: 32, height: 32)
                .background(AppColor.bgSunken)
                .clipShape(Circle())

            Text("Aún no tienes hábitos activos. Puedes guardar el plan y vincularlos después.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgSunken.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }
}

private struct HabitSelectionRow: View {
    let habit: Habit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(habit.habitColor.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: habit.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(habit.habitColor)
                }

                Text(habit.title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.accent : AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(isSelected ? AppColor.accentMuted.opacity(0.5) : AppColor.bgSunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(isSelected ? AppColor.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
