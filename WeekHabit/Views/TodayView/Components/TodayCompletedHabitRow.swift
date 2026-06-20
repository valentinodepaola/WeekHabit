//
//  TodayCompletedHabitRow.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 06/06/26.
//

import SwiftUI

struct TodayCompletedHabitRow: View {
    let habit: Habit
    let metadata: String
    var isMinimumCompleted: Bool = false
    var onOpenDetail: (() -> Void)? = nil
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            Button(action: onToggle) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(isMinimumCompleted ? habit.habitColor.opacity(0.55) : habit.habitColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                            .strokeBorder(isMinimumCompleted ? habit.habitColor : Color.clear, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isMinimumCompleted ? "Marcar completo \(habit.title)" : "Desmarcar \(habit.title)")

            HStack(spacing: AppSpacing.m) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(habit.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(isMinimumCompleted ? AppColor.textPrimary.opacity(0.72) : AppColor.textSecondary)
                        .strikethrough(!isMinimumCompleted, color: AppColor.textSecondary)
                        .lineLimit(1)

                    Text(metadata)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                completedIconBadge
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onOpenDetail?()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Ver detalle")
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(isMinimumCompleted ? AppColor.bgElevated.opacity(0.88) : AppColor.bgElevated.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(
                    isMinimumCompleted ? habit.habitColor.opacity(0.28) : AppColor.divider.opacity(0.7),
                    lineWidth: 1
                )
        }
    }

    private var completedIconBadge: some View {
        ZStack {
            Circle()
                .fill(habit.habitColor.opacity(0.14))

            Image(systemName: habit.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(habit.habitColor)
        }
        .frame(width: 38, height: 38)
        .accessibilityHidden(true)
    }
}
