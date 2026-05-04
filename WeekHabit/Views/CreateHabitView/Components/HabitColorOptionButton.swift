//
//  HabitColorOptionButton.swift
//  WeekHabit
//

import SwiftUI

struct HabitColorOptionButton: View {
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        HabitAppearance.color(for: colorHex)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(color)
                    .frame(height: 48)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .stroke(isSelected ? color.opacity(0.55) : Color.clear, lineWidth: 4)
            }
        }
        .buttonStyle(.plain)
    }
}
