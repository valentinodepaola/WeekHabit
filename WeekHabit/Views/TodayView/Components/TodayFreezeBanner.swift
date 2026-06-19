//
//  TodayFreezeBanner.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 06/06/26.
//

import SwiftUI

struct TodayFreezeBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.info)
                .frame(width: 30, height: 30)
                .background(AppColor.info.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(message)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Un comodín protege un día difícil sin romper tu racha.")
                    .font(AppFont.micro)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(AppColor.bgElevated.opacity(0.7))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ocultar explicación de comodín")
            }
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.info.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.info.opacity(0.22), lineWidth: 1)
        }
    }
}
