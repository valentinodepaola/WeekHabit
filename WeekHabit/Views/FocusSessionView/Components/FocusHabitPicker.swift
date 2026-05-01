//
//  FocusHabitPicker.swift
//  WeekHabit
//

import SwiftUI

struct FocusHabitPicker: View {
    let habits: [Habit]
    @Binding var selectedHabitIDs: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÁBITOS")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .tracking(1.3)

            VStack(spacing: 10) {
                ForEach(habits) { habit in
                    Button {
                        toggle(habit)
                    } label: {
                        HStack(spacing: 12) {
                            IconComponent(
                                icon: habit.displayCategory.icon,
                                color: habit.displayCategory.color
                            )

                            Text(habit.title)
                                .font(AppFont.body2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.strongText)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: selectedHabitIDs.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(selectedHabitIDs.contains(habit.id) ? AppColor.accent : AppColor.subtleText)
                        }
                        .padding(14)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
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
