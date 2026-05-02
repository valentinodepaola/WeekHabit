//
//  HabitOptionButton.swift
//  WeekHabit
//

import SwiftUI

struct HabitOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : AppColor.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : AppColor.strongText)

                    Text(subtitle)
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : AppColor.subtleText)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(14)
            .background(isSelected ? AppColor.accent : AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
