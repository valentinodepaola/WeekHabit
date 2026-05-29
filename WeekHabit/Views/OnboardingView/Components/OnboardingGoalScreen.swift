//
//  OnboardingGoalScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingGoalScreen: View {
    @Binding var goalText: String
    @FocusState private var isFocused: Bool

    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("Escríbela con tus palabras. No hay respuesta incorrecta.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)

            TextField(
                "Ej: Mejorar mi condición física, aprender a programar, leer más...",
                text: $goalText,
                axis: .vertical
            )
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .lineLimit(3...6)
            .focused($isFocused)
            .padding(AppSpacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(AppColor.bgSunken)
            )
            .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.l)

            onboardingArtwork

            WHButton(title: "Continuar", variant: .primary, action: onContinue)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.s)

            Button("Omitir", action: onSkip)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .padding(.bottom, AppSpacing.xxl)
        }
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("¿Qué quieres")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("lograr?")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }

    private var onboardingArtwork: some View {
        Image("OnboardingPlanningGirl")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .clipped()
            .padding(.bottom, AppSpacing.s)
            .accessibilityHidden(true)
    }
}

#Preview {
    AppBackground {
        OnboardingGoalScreen(goalText: .constant(""), onContinue: {}, onSkip: {})
    }
}
