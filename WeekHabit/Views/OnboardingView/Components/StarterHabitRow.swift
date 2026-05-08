//
//  StarterHabitRow.swift
//  WeekHabit
//

import SwiftUI

struct StarterHabitRow: View {
    let template: StarterHabitTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                        .fill(template.color.opacity(0.18))
                    Image(systemName: template.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(template.color)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(template.subtitle)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : AppColor.divider, lineWidth: 1.4)
                        .frame(width: 30, height: 30)

                    if isSelected {
                        Circle()
                            .fill(template.color)
                            .frame(width: 30, height: 30)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.l)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(isSelected ? template.color.opacity(0.16) : AppColor.bgElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(isSelected ? template.color : AppColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
