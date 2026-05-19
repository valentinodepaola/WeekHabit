//
//  OnboardingMotivationScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingMotivationScreen: View {
    @Binding var motivationText: String
    @FocusState private var isFocused: Bool

    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("El porqué hace que sea más fácil volver cuando el hábito falla.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)

            TextField(
                "Ej: Quiero tener más energía, sentirme orgulloso, estar presente...",
                text: $motivationText,
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

            Spacer()

            WHButton(title: "Continuar", variant: .primary, action: onContinue)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.s)

            Button("Saltear", action: onSkip)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .padding(.bottom, AppSpacing.xxl)
        }
        .onAppear { isFocused = true }
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("¿Por qué")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("importa esto?")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }
}

#Preview {
    AppBackground {
        OnboardingMotivationScreen(motivationText: .constant(""), onContinue: {}, onSkip: {})
    }
}
