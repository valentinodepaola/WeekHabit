//
//  StreakBreakdownCard.swift
//  WeekHabit
//

import SwiftUI

struct StreakBreakdownCard: View {
    let habit: Habit
    let breakdown: StreakBreakdown
    let color: Color

    private var totalLabel: String {
        IdentityReinforcementCopy.streakBreakdownTotal(
            for: habit,
            totalDays: breakdown.totalDays
        )
    }

    private var statusText: String {
        IdentityReinforcementCopy.streakBreakdownStatus(
            for: habit,
            breakdown: breakdown
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(IdentityReinforcementCopy.streakBreakdownHeader(for: habit).uppercased(with: Locale(identifier: "es_MX")))
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)

                Spacer()

                Text(totalLabel)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
            }

            HStack(spacing: AppSpacing.s) {
                StreakBreakdownMetric(
                    icon: habit.isBreakHabit ? "xmark" : "checkmark",
                    value: breakdown.completedDays,
                    label: breakdown.completedDays == 1
                        ? (habit.isBreakHabit ? "evitado" : "hecho")
                        : (habit.isBreakHabit ? "evitados" : "hechos"),
                    tint: color,
                    fill: color.opacity(0.16)
                )

                StreakBreakdownMetric(
                    icon: "checkmark.circle",
                    value: breakdown.minimumDays,
                    label: breakdown.minimumDays == 1 ? "mínimo" : "mínimos",
                    tint: color,
                    fill: color.opacity(0.10)
                )

                StreakBreakdownMetric(
                    icon: "pause.fill",
                    value: breakdown.skippedDays,
                    label: breakdown.skippedDays == 1 ? "descanso" : "descansos",
                    tint: color,
                    fill: color.opacity(0.09)
                )

                StreakBreakdownMetric(
                    icon: "shield.fill",
                    value: breakdown.frozenDays,
                    label: breakdown.frozenDays == 1 ? "comodín" : "comodines",
                    tint: AppColor.info,
                    fill: AppColor.info.opacity(0.12)
                )
            }

            Text(statusText)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
}

private struct StreakBreakdownMetric: View {
    let icon: String
    let value: Int
    let label: String
    let tint: Color
    let fill: Color

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.s) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .fill(fill)
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text("\(value)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()

            Text(label)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        StreakBreakdownCard(
            habit: Habit(
                title: "Leer antes de dormir",
                iconName: "book.fill",
                colorHex: "#5c89a8",
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered)
            ),
            breakdown: StreakBreakdown(completedDays: 18, minimumDays: 2, skippedDays: 4, frozenDays: 1),
            color: AppColor.accent
        )

        StreakBreakdownCard(
            habit: Habit(
                title: "Comprar cosas por impulso",
                iconName: "cart.fill",
                colorHex: "#7fa774",
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered),
                direction: .break
            ),
            breakdown: StreakBreakdown(completedDays: 5, minimumDays: 0, skippedDays: 0, frozenDays: 0),
            color: AppColor.success
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
