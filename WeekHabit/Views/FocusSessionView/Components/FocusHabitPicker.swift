//
//  FocusHabitPicker.swift
//  WeekHabit
//

import SwiftUI

struct FocusHabitPicker: View {
    let habits: [Habit]
    @Binding var selectedHabitIDs: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("HÁBITOS")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)

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

                            Text(habit.title)
                                .font(AppFont.bodyEmphasis)
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: selectedHabitIDs.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(selectedHabitIDs.contains(habit.id) ? AppColor.accent : AppColor.textTertiary)
                        }
                        .padding(AppSpacing.m)
                        .background(AppColor.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggle(_ habit: Habit) {
        if selectedHabitIDs.contains(habit.id) {
            selectedHabitIDs.remove(habit.id)
        } else {
            selectedHabitIDs.insert(habit.id)
        }
    }
}
