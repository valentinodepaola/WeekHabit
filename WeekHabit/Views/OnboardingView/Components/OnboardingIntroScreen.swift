//
//  OnboardingIntroScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingIntroScreen: View {
    let onStart: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RippleLogoView()
                .padding(.bottom, AppSpacing.l)

            VStack(spacing: AppSpacing.s) {
                headlineText
                    .multilineTextAlignment(.center)

                Text("Construye hábitos que sí se sostienen: una semana a la vez, con espacio para volver.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.top, AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            WHButton(title: "Empezar", variant: .primary, action: onStart)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.l)

            Button("Saltar introducción", action: onSkip)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .padding(.bottom, AppSpacing.xxl)
        }
    }

    private var headlineText: some View {
        VStack(spacing: 4) {
            Text("Una semana.")
                .font(.system(size: 38, weight: .regular, design: .serif))
                .foregroundStyle(AppColor.textPrimary)

            Text("Un ritmo.")
                .font(.system(size: 38, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(AppColor.accent)
        }
    }
}
