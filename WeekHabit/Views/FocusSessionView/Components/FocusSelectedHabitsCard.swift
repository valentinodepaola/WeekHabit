//
//  FocusSelectedHabitsCard.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct FocusSelectedHabitsCard: View {
    let habits: [Habit]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("EN ESTA SESIÓN")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)

            VStack(spacing: AppSpacing.s) {
                ForEach(habits) { habit in
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
                    }
                    .padding(AppSpacing.m)
                    .background(AppColor.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                }
            }
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @Query(sort: \Habit.createdAt) var habits: [Habit]

    FocusSelectedHabitsCard(habits: Array(habits.prefix(3)))
        .padding()
        .background(AppColor.bgCanvas)
}
