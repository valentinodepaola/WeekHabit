//
//  StreakBreakdownCard.swift
//  WeekHabit
//

import SwiftUI

struct StreakBreakdownCard: View {
    let breakdown: StreakBreakdown
    let color: Color

    private var totalLabel: String {
        "\(breakdown.totalDays) \(breakdown.totalDays == 1 ? "día sostenido" : "días sostenidos")"
    }

    private var statusText: String {
        if !breakdown.hasHistory {
            return "Aún no hay una racha activa para desglosar."
        }

        if breakdown.protectedDays == 0 {
            return "Tu racha viene solo de días completados."
        }

        return "Los descansos y comodines mantuvieron la racha sin contarlos como días hechos."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("RACHA HONESTA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Spacer()

                Text(totalLabel)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
            }

            HStack(spacing: AppSpacing.s) {
                StreakBreakdownMetric(
                    icon: "checkmark",
                    value: breakdown.completedDays,
                    label: breakdown.completedDays == 1 ? "hecho" : "hechos",
                    tint: color,
                    fill: color.opacity(0.16)
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
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
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
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .fill(fill)
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text("\(value)")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()

            Text(label)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
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
            breakdown: StreakBreakdown(completedDays: 18, skippedDays: 4, frozenDays: 1),
            color: AppColor.accent
        )

        StreakBreakdownCard(
            breakdown: StreakBreakdown(completedDays: 5, skippedDays: 0, frozenDays: 0),
            color: AppColor.success
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
