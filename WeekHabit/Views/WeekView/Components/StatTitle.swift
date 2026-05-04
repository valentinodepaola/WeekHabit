//
//  StatTitle.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//
import SwiftUI

struct StatTile: View {
    
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(value == "—" ? 0.08 : 0.14))
                    .frame(width: 30, height: 30)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(AppFont.subtitle2)
                .foregroundStyle(value == "—" ? AppColor.subtleText : AppColor.strongText)
                .contentTransition(.numericText())

            Text(label)
                .font(AppFont.formSectionText2)
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(AppColor.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(AppColor.subtleText.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: AppColor.strongText.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var iconColor: Color {
        value == "—" ? AppColor.subtleText : AppColor.accent
    }
}
