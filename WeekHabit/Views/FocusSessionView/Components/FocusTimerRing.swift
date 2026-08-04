//
//  FocusTimerRing.swift
//  WeekHabit
//
//  Temporizador circular estilo Apple. El anillo se consume conforme pasa el
//  tiempo y el centro muestra el tiempo restante. Reusa WHProgressRing.
//

import SwiftUI

struct FocusTimerRing: View {
    let timeText: String
    let subtitle: String
    /// Fracción restante (0...1). `nil` en sesiones libres (sin total): el
    /// anillo se muestra lleno y el centro cuenta el tiempo transcurrido.
    let remainingFraction: Double?

    var body: some View {
        WHProgressRing(
            progress: remainingFraction ?? 1,
            lineWidth: 14,
            size: 240,
            trackColor: AppColor.divider,
            progressColor: AppColor.accent
        ) {
            VStack(spacing: AppSpacing.xs) {
                Text(timeText)
                    .font(.system(size: 60, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(subtitle)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
