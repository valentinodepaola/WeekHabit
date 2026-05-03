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
                .padding(.bottom, 18)

            VStack(spacing: 8) {
                Text("Una semana.")
                    .font(AppFont.title1)
                    .foregroundStyle(AppColor.strongText)

                Text("Un ritmo.")
                    .font(AppFont.title1.italic())
                    .foregroundStyle(AppColor.accent)

                Text("Construye hábitos que sí se sostienen: día a día, sin presión.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 46)
                    .padding(.top, 4)
            }

            Spacer()

            OnboardingPrimaryButton(title: "Iniciar onboarding", action: onStart)
                .padding(.horizontal, 28)
                .padding(.bottom, 22)

            Button("Ya tengo una cuenta", action: onSkip)
                .font(AppFont.captionApp)
                .foregroundStyle(AppColor.subtleText)
                .padding(.bottom, 32)
        }
    }
}
