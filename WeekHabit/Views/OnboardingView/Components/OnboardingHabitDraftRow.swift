//
//  OnboardingHabitDraftRow.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingHabitDraftRow: View {
    @Binding var draft: OnboardingHabitDraft
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(draft.color.opacity(0.18))
                Image(systemName: draft.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(draft.color)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                TextField("Nombre del hábito", text: $draft.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)

                Text(draft.frequencyText)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AppColor.bgSunken))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.l)
        .frame(minHeight: 74)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .fill(AppColor.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }
}
