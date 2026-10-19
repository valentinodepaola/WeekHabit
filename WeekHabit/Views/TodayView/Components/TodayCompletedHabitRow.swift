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
    /// Presente cuando el hábito descansa porque ya cumplió su meta semanal: el toque muestra
    /// este aviso en lugar de registrar.
    var weeklyRestNotice: String? = nil
    var onOpenDetail: (() -> Void)? = nil
    let onToggle: () -> Void

    @State private var showsWeeklyRestNotice = false

    private var restsOnWeeklyTarget: Bool {
        weeklyRestNotice != nil
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            Button(action: handleToggle) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(restsOnWeeklyTarget ? habit.habitColor : .white)
                    .frame(width: 32, height: 32)
                    .background(toggleFill)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                            .strokeBorder(toggleBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(toggleAccessibilityLabel)
            .accessibilityHint(weeklyRestNotice ?? "")
            .popover(isPresented: $showsWeeklyRestNotice) {
                Text(weeklyRestNotice ?? "")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(idealWidth: 240)
                    .padding(AppSpacing.m)
                    .presentationCompactAdaptation(.popover)
            }

            HStack(spacing: AppSpacing.m) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(habit.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(isMinimumCompleted ? AppColor.textPrimary.opacity(0.72) : AppColor.textSecondary)
                        .strikethrough(!isMinimumCompleted && !restsOnWeeklyTarget, color: AppColor.textSecondary)
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

    private func handleToggle() {
        guard restsOnWeeklyTarget else {
            onToggle()
            return
        }
        AppHaptics.play(.selection)
        showsWeeklyRestNotice = true
    }

    private var toggleFill: Color {
        if restsOnWeeklyTarget {
            return habit.habitColor.opacity(0.14)
        }
        return isMinimumCompleted ? habit.habitColor.opacity(0.55) : habit.habitColor
    }

    private var toggleBorder: Color {
        if restsOnWeeklyTarget {
            return habit.habitColor.opacity(0.5)
        }
        return isMinimumCompleted ? habit.habitColor : Color.clear
    }

    private var toggleAccessibilityLabel: String {
        if restsOnWeeklyTarget {
            return "\(habit.title): meta de la semana cumplida"
        }
        return isMinimumCompleted ? "Marcar completo \(habit.title)" : "Desmarcar \(habit.title)"
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
