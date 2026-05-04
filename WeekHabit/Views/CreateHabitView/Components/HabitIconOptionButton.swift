//
//  HabitIconOptionButton.swift
//  WeekHabit
//

import SwiftUI

struct HabitIconOptionButton: View {
    let iconName: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? .white : selectedColor)
                .frame(width: 48, height: 48)
                .background(isSelected ? selectedColor : AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(isSelected ? Color.clear : AppColor.subtleText.opacity(0.14), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
