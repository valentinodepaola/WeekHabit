//
//  StatTitle.swift
//  WeekHabit
//

import SwiftUI

struct StatTile: View {
    let label: String
    let value: String
    let icon: String

    private var isEmpty: Bool { value == "—" }

    private var iconColor: Color {
        isEmpty ? AppColor.textTertiary : AppColor.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(isEmpty ? 0.08 : 0.14))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 30, height: 30)

            Text(value)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(isEmpty ? AppColor.textTertiary : AppColor.textPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(AppSpacing.m)
        .background(AppColor.bgElevated)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
}
