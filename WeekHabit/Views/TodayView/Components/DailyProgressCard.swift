//
//  DailyProgressCard.swift
//  WeekHabit
//

import SwiftUI

struct DailyProgressCard: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    let remainingCount: Int

    private var ringColor: Color {
        if totalCount == 0 { return AppColor.textTertiary }
        if remainingCount == 0 { return AppColor.success }
        return AppColor.accent
    }

    private var headlineText: String {
        if totalCount == 0 { return "Sin hábitos hoy" }
        if remainingCount == 0 { return "Día cerrado" }
        if remainingCount == 1 { return "Te falta uno" }
        return "Te faltan \(remainingCount)"
    }

    private var supportText: String {
        if totalCount == 0 {
            return "El descanso también construye semana."
        }
        if remainingCount == 0 {
            return "Llegaste a tu meta de hoy."
        }
        return "Un paso pequeño cuenta."
    }

    var body: some View {
        WHCard(variant: .elevated, padding: AppSpacing.l, radius: AppRadius.l) {
            HStack(spacing: AppSpacing.l) {
                WHProgressRing(
                    progress: progress,
                    lineWidth: 8,
                    size: 86,
                    progressColor: ringColor
                ) {
                    VStack(spacing: 0) {
                        Text("\(completedCount)")
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .foregroundStyle(AppColor.textPrimary)
                            .monospacedDigit()
                        Text("de \(totalCount)")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                            .monospacedDigit()
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("HOY")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1)

                    Text(headlineText)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(supportText)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        DailyProgressCard(progress: 0.66, completedCount: 2, totalCount: 3, remainingCount: 1)
        DailyProgressCard(progress: 1.0, completedCount: 3, totalCount: 3, remainingCount: 0)
        DailyProgressCard(progress: 0.0, completedCount: 0, totalCount: 0, remainingCount: 0)
    }
    .padding()
    .background(AppColor.bgCanvas)
}
