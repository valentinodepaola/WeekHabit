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
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(isSelected ? AppColor.surface : Color.clear)
                        .frame(width: 48, height: 48)

                    Image(systemName: template.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(template.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(AppFont.body2.bold())
                        .foregroundStyle(AppColor.strongText)

                    Text(template.subtitle)
                        .font(AppFont.captionApp)
                        .foregroundStyle(AppColor.subtleText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(isSelected ? template.color.opacity(0) : AppColor.subtleText.opacity(0.24), lineWidth: 1.4)
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
            .padding(.horizontal, 18)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? template.color.opacity(0.16) : AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? template.color : Color.clear, lineWidth: 1.4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
