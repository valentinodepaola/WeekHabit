//
//  OnboardingNotificationsScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingNotificationsScreen: View {
    let onRequestNotifications: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            iconBadge
                .padding(.bottom, AppSpacing.xxl)

            VStack(spacing: AppSpacing.m) {
                headlineText
                    .multilineTextAlignment(.center)

                Text("Te avisamos cuando toca tu hábito. Tú decides hora y frecuencia, sin spam.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxxl)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            WHButton(
                title: "Activar recordatorios",
                icon: "bell",
                variant: .primary,
                action: onRequestNotifications
            )
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.s)

            Button("Más tarde", action: onSkip)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .padding(.bottom, AppSpacing.xxl)
        }
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.accent, AppColor.warning],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 116, height: 116)

            Image(systemName: "bell")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.white)
        }
        .appElevation(.medium)
    }

    private var headlineText: some View {
        VStack(spacing: 2) {
            Text("Un empujón")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("en el momento justo")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }
}
