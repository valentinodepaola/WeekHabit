//
//  FocusReviewChecklist.swift
//  WeekHabit
//

import SwiftUI

struct FocusReviewChecklist: View {
    let habits: [Habit]
    @Binding var completedHabitIDs: Set<UUID>

    var body: some View {
        VStack(spacing: 10) {
            ForEach(habits) { habit in
                Button {
                    toggle(habit)
                } label: {
                    HStack(spacing: 12) {
                        IconComponent(
                            icon: habit.iconName,
                            color: habit.habitColor
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(AppFont.body2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.strongText)
                                .lineLimit(1)

                            Text("Completado durante la sesión")
                                .font(AppFont.formSectionText2)
                                .foregroundStyle(AppColor.mutedText)
                        }

                        Spacer()

                        Image(systemName: completedHabitIDs.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(completedHabitIDs.contains(habit.id) ? AppColor.accent : AppColor.subtleText)
                    }
                    .padding(14)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
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
