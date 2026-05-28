//
//  OnboardingSizeScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingSizeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("La meta puede verse grande. Lo que la vuelve posible son pasos pequeños, repetidos con calma.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.l)

            insightText
                .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.l)

            onboardingArtwork

            WHButton(title: "Continuar", variant: .primary, action: onContinue)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxl)
        }
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Empezar")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("lo más pequeño posible")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }

    private var insightText: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("No necesitas empezar perfecto.")
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)

            Text("Un hábito pequeño baja la fricción, te deja repetirlo incluso en días difíciles y crea evidencia de que sí puedes avanzar.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var onboardingArtwork: some View {
        Image("OnboardingBabySteps")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()
            .padding(.bottom, AppSpacing.s)
            .accessibilityHidden(true)
    }
}

#Preview {
    AppBackground {
        OnboardingSizeScreen(onContinue: {})
    }
}
