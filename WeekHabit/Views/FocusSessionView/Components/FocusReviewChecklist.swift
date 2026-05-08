//
//  FocusReviewChecklist.swift
//  WeekHabit
//

import SwiftUI

struct FocusReviewChecklist: View {
    let habits: [Habit]
    @Binding var completedHabitIDs: Set<UUID>

    var body: some View {
        VStack(spacing: AppSpacing.s) {
            ForEach(habits) { habit in
                Button {
                    toggle(habit)
                } label: {
                    HStack(spacing: AppSpacing.m) {
                        ZStack {
                            Circle()
                                .fill(habit.habitColor.opacity(0.18))
                            Image(systemName: habit.iconName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(habit.habitColor)
                        }
                        .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(AppFont.bodyEmphasis)
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(1)
                            Text("Completado durante la sesión")
                                .font(AppFont.label)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        Spacer()

                        Image(systemName: completedHabitIDs.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(completedHabitIDs.contains(habit.id) ? AppColor.accent : AppColor.textTertiary)
                    }
                    .padding(AppSpacing.m)
                    .background(AppColor.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ habit: Habit) {
        if completedHabitIDs.contains(habit.id) {
            completedHabitIDs.remove(habit.id)
        } else {
            completedHabitIDs.insert(habit.id)
        }
    }
}
