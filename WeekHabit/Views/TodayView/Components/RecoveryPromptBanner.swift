//
//  RecoveryPromptBanner.swift
//  WeekHabit
//

import SwiftUI

/// Reentrada a la hoja de recuperación mientras queden pendientes de ayer sin responder.
///
/// La hoja se auto-presenta una sola vez al día; si el usuario la cerró, este banner es la forma
/// de volver a ella sin esperar a mañana —para entonces la ventana de ayer ya se cerró—.
/// Calca a `WeeklyReviewBanner`, que ya ocupa ese lugar en la lista de Hoy.
struct RecoveryPromptBanner: View {
    let pendingCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 32, height: 32)
                    .background(AppColor.accentMuted)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(titleText)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text("Cuéntanos qué pasó")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(AppColor.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(AppColor.accent.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Abrir los pendientes de ayer")
    }

    private var titleText: String {
        pendingCount == 1
            ? "Ayer quedó 1 sin marcar"
            : "Ayer quedaron \(pendingCount) sin marcar"
    }
}
