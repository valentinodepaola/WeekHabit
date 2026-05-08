//
//  FocusTimerCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusTimerCard: View {
    let timeText: String
    let progress: Double?
    let selectedCount: Int
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.l) {
            VStack(spacing: AppSpacing.s) {
                Text(timeText)
                    .font(.system(size: 66, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(selectedCount == 1 ? "1 hábito en enfoque" : "\(selectedCount) hábitos en enfoque")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
            }

            if let progress {
                WHProgressBar(
                    progress: progress,
                    progressColor: AppColor.accent,
                    height: 6
                )
            }

            WHButton(title: "Terminar sesión", variant: .primary, action: onFinish)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .appElevation(.low)
    }
}
