//
//  WeeklyReviewHeader.swift
//  WeekHabit
//

import SwiftUI

struct WeeklyReviewHeader: View {
    let weekRangeText: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(weekRangeText.uppercased(with: Locale(identifier: "es_MX")))
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)

                Text("Tu semana")
                    .font(AppFont.title.bold())
                    .foregroundStyle(AppColor.textPrimary)

                Text("Una pausa breve para quedarte con lo que funcionó y ajustar lo que pide otro ritmo.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppColor.bgElevated)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar revisión")
        }
    }
}
