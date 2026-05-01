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
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(value == "—" ? AppColor.subtleText : AppColor.accent)

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
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}
