//
//  FocusSessionLauncherCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusSessionLauncherCard: View {
    let remainingCount: Int
    let onStart: () -> Void

    private var detail: String {
        if remainingCount == 0 {
            return "Para registrar hábitos en tiempo real."
        }
        if remainingCount == 1 {
            return "Enfócate en 1 hábito y deja una marca confiable."
        }
        return "Enfócate en \(remainingCount) hábitos y deja marcas confiables."
    }

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(AppColor.accentMuted)
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColor.accent)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sesión de ritmo")
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(detail)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: AppSpacing.s)

                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
            .padding(AppSpacing.m)
            .background(AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
