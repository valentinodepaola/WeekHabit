//
//  OnboardingAreaCard.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingAreaCard: View {
    let option: OnboardingAreaOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(AppColor.surface)
                        .frame(width: 38, height: 38)

                    Image(systemName: option.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(option.color)
                }

                Text(option.title)
                    .font(AppFont.subtitle2)
                    .foregroundStyle(AppColor.strongText)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(isSelected ? option.color.opacity(0.16) : AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? option.color : Color.clear, lineWidth: 1.4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
