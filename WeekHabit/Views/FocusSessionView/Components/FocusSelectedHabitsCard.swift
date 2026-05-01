//
//  FocusSelectedHabitsCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusSelectedHabitsCard: View {
    let habits: [Habit]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EN ESTA SESIÓN")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .tracking(1.3)

            VStack(spacing: 10) {
                ForEach(habits) { habit in
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
                    }
                    .padding(14)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                }
            }
        }
    }
}
