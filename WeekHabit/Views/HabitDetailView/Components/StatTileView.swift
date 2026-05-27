//
//  StatTileView.swift
//  WeekHabit
//

import SwiftUI

struct StatTileView: View {
    let caption: String
    let value: String
    let footer: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(caption)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)

            Text(value)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .monospacedDigit()

            Text(footer)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
}

#Preview {
    HStack(spacing: AppSpacing.s) {
        StatTileView(caption: "ESTA SEMANA", value: "3/5", footer: "60% de meta")
        StatTileView(caption: "REFERENCIA", value: "8", footer: "tu mejor versión hasta hoy")
    }
    .padding()
    .background(AppColor.bgCanvas)
}
