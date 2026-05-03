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

            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColor.accent, Color(hex: "#df7442")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 116, height: 116)

                Image(systemName: "bell")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppColor.accent.opacity(0.14), radius: 28, x: 0, y: 18)
            .padding(.bottom, 44)

            VStack(spacing: 14) {
                (
                    Text("Un empujón ")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)
                    +
                    Text("en el momento justo")
                        .font(AppFont.title.italic())
                        .foregroundStyle(AppColor.accent)
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                Text("Te avisamos cuando toca tu hábito. Tú decides hora y frecuencia, sin spam, lo prometemos.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 48)
            }

            Spacer()

            OnboardingPrimaryButton(title: "Activar notificaciones", action: onRequestNotifications)
                .padding(.horizontal, 28)
                .padding(.bottom, 22)

            Button("Más tarde", action: onSkip)
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .padding(.bottom, 34)
        }
    }
}
