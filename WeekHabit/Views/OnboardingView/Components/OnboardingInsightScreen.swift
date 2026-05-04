//
//  OnboardingInsightScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingInsightScreen: View {
    let icon: String
    let title: String
    let accentTitle: String
    let message: String
    let buttonTitle: String
    let onContinue: () -> Void

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
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppColor.accent.opacity(0.16), radius: 30, x: 0, y: 20)
            .padding(.bottom, 42)

            VStack(spacing: 8) {
                Text(title)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.strongText)
                    .multilineTextAlignment(.center)

                Text(accentTitle)
                    .font(AppFont.title.italic())
                    .foregroundStyle(AppColor.accent)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 34)
                    .padding(.top, 14)
            }

            Spacer()

            OnboardingPrimaryButton(title: buttonTitle, action: onContinue)
                .padding(.horizontal, 28)
                .padding(.bottom, 34)
        }
    }
}
