//
//  WHChip.swift
//  WeekHabit
//
//  Chip pequeño para selectores, filtros y tags.
//  Estados: idle, selected, disabled.
//

import SwiftUI

struct WHChip: View {
    let label: String
    var icon: String? = nil
    var isSelected: Bool = false
    var isDisabled: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(label)
                    .font(AppFont.label)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || action == nil)
        .opacity(isDisabled ? 0.4 : 1)
    }

    private var backgroundColor: Color {
        isSelected ? AppColor.accentMuted : AppColor.bgElevated
    }

    private var foregroundColor: Color {
        isSelected ? AppColor.accent : AppColor.textSecondary
    }

    private var borderColor: Color {
        isSelected ? AppColor.accent.opacity(0.4) : AppColor.divider
    }
}
