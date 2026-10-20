//
//  FocusSessionLauncherCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusSessionLauncherCard: View {
    let remainingCount: Int
    let onStart: () -> Void

    /// Una sola línea, para que la tarjeta vaya con el ritmo de la lista de hábitos.
    private var detail: String {
        if remainingCount == 0 {
            return "Registra en tiempo real"
        }
        if remainingCount == 1 {
            return "1 hábito · marca confiable"
        }
        return "\(remainingCount) hábitos · marcas confiables"
    }

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(AppColor.accentMuted)
                    Image(systemName: "timer")
                        .font(AppFont.iconSmall)
                        .foregroundStyle(AppColor.accent)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sesión de ritmo")
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(detail)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.s)

                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
            .padding(.vertical, AppSpacing.s)
            .padding(.horizontal, AppSpacing.m)
            .background(AppColor.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(AppColor.accent.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        FocusSessionLauncherCard(remainingCount: 3, onStart: {})
        FocusSessionLauncherCard(remainingCount: 1, onStart: {})
        FocusSessionLauncherCard(remainingCount: 0, onStart: {})
    }
    .padding()
    .background(AppColor.bgCanvas)
}
