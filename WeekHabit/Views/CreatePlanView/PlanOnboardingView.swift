//
//  PlanOnboardingView.swift
//  WeekHabit
//

import SwiftUI

struct PlanOnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                Spacer()

                EmptyStateIcon(
                    iconColor: AppColor.accent,
                    fillColor: AppColor.accentSoft,
                    insideCirculeColor: AppColor.accentSoft,
                    icon: "target"
                )
                .padding(.bottom, 32)

                VStack(spacing: 6) {
                    Text("Tus hábitos,")
                        .font(AppFont.title1)
                        .foregroundStyle(AppColor.strongText)
                    Text("con propósito.")
                        .font(AppFont.title1.italic())
                        .foregroundStyle(AppColor.accent)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

                Text("Un Plan agrupa los hábitos que trabajas hacia un objetivo concreto.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 36)

                VStack(spacing: 16) {
                    PlanOnboardingPoint(
                        icon: "square.stack.3d.up",
                        title: "Agrupa hábitos por objetivo",
                        subtitle: "\"Maratón de septiembre\", \"Mes sin alcohol\", lo que sea."
                    )
                    PlanOnboardingPoint(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Seguí tu avance en tiempo real",
                        subtitle: "Porcentaje de completitud y días restantes siempre a la vista."
                    )
                    PlanOnboardingPoint(
                        icon: "checkmark.seal",
                        title: "Al terminar, vos decidís",
                        subtitle: "El plan cierra, pero los hábitos que quieras se quedan."
                    )
                }
                .padding(.horizontal, 28)

                Spacer()

                IconButton(
                    icon: "target",
                    text: "Crear mi primer plan",
                    style: .pill,
                    action: onContinue
                )
                .padding(.horizontal)
                .padding(.bottom, 12)

                Button("Saltar introducción", action: onContinue)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
                    .padding(.bottom, 32)
            }
        }
    }
}

private struct PlanOnboardingPoint: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .foregroundStyle(AppColor.accentSoft)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.body2.bold())
                    .foregroundStyle(AppColor.strongText)

                Text(subtitle)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PlanOnboardingView(onContinue: { })
}
