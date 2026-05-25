//
//  WeeklyReflectionPromptCard.swift
//  WeekHabit
//

import SwiftUI

struct WeeklyReflectionPromptCard: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)

                Text("NOTA DE REFLEXIÓN")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)
            }

            Text("¿Qué aprendiste de tu ritmo esta semana?")
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)

            TextEditor(text: $text)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 92)
                .padding(AppSpacing.s)
                .background(AppColor.bgSunken.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                        .strokeBorder(AppColor.divider, lineWidth: 1)
                }
        }
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
}
